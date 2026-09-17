#include <Arduino.h>
#include <NimBLEDevice.h>

#include "bmi270_stub.h"
#include "toporoom_hub_protocol.h"
#include "uart_laser.h"

#ifndef TOPOROOM_HUB_FW_VERSION
#define TOPOROOM_HUB_FW_VERSION TOPOROOM_HUB_FW_DEFAULT
#endif
#ifndef TOPOROOM_HUB_SKU
#define TOPOROOM_HUB_SKU TOPOROOM_HUB_SKU_DEFAULT
#endif
#ifndef LASER_UART_BAUD
#define LASER_UART_BAUD 19200
#endif
#ifndef LASER_UART_TX_PIN
#define LASER_UART_TX_PIN 4
#endif
#ifndef LASER_UART_RX_PIN
#define LASER_UART_RX_PIN 5
#endif
#ifndef LASER_EN_PIN
#define LASER_EN_PIN 6
#endif
#ifndef LASER_DIST_SCALE
#define LASER_DIST_SCALE 1
#endif
#ifndef BMI270_SDA_PIN
#define BMI270_SDA_PIN 8
#endif
#ifndef BMI270_SCL_PIN
#define BMI270_SCL_PIN 9
#endif
#ifndef TOPOROOM_LASER_SIM
#define TOPOROOM_LASER_SIM 0
#endif

namespace {

NimBLECharacteristic* g_length = nullptr;
NimBLECharacteristic* g_battery = nullptr;
NimBLECharacteristic* g_status = nullptr;

volatile bool g_pending = false;
volatile uint8_t g_opcode = 0;
volatile uint8_t g_flags = 0;
volatile uint16_t g_timeout_ms = 1000;
uint16_t g_seq = 0;
bool g_busy = false;

void notify_length(int32_t mm, uint8_t status, uint8_t source) {
  uint8_t buf[TOPOROOM_HUB_LENGTH_NOTIFY_SIZE];
  ++g_seq;
  toporoom_hub_pack_length_notify(buf, mm, status, source, g_seq, millis());
  if (g_length) {
    g_length->setValue(buf, sizeof(buf));
    g_length->notify();
  }
  if (g_status) {
    uint8_t st = status;
    g_status->setValue(&st, 1);
  }
}

class MeasureCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* chr) override {
    const std::string value = chr->getValue();
    uint8_t opcode = 0;
    uint8_t flags = 0;
    uint16_t timeout = 0;
    if (toporoom_hub_parse_measure_cmd(reinterpret_cast<const uint8_t*>(value.data()),
                                       value.size(), &opcode, &flags, &timeout) != 0) {
      notify_length(-1, TOPOROOM_HUB_STATUS_BAD_CMD, TOPOROOM_HUB_SOURCE_INVALID);
      return;
    }
    if ((flags & TOPOROOM_HUB_FLAG_REQUIRE_LASER) == 0) {
      notify_length(-1, TOPOROOM_HUB_STATUS_RF_REJECTED, TOPOROOM_HUB_SOURCE_INVALID);
      return;
    }
    if (g_busy || g_pending) {
      notify_length(-1, TOPOROOM_HUB_STATUS_BUSY, TOPOROOM_HUB_SOURCE_INVALID);
      return;
    }
    g_opcode = opcode;
    g_flags = flags;
    g_timeout_ms = timeout == 0 ? 1000 : timeout;
    g_pending = true;
  }
};

MeasureCallbacks g_measure_cb;

}  // namespace

void setup() {
  Serial.begin(115200);
  delay(200);
  Serial.printf("TopoRoom hub %s sku=%s sim=%d\n", TOPOROOM_HUB_FW_VERSION, TOPOROOM_HUB_SKU,
                TOPOROOM_LASER_SIM);

  uart_laser_begin(LASER_UART_BAUD, LASER_UART_TX_PIN, LASER_UART_RX_PIN, LASER_EN_PIN);
  uart_laser_set_sim(TOPOROOM_LASER_SIM);
  bmi270_stub_begin(BMI270_SDA_PIN, BMI270_SCL_PIN);
  Serial.printf("bmi270 present=%d chip_id=0x%02x (P0 unused; phone IMU)\n",
                bmi270_stub_present(), bmi270_stub_chip_id());

  NimBLEDevice::init(TOPOROOM_HUB_ADV_NAME);
  NimBLEDevice::setPower(ESP_PWR_LVL_P9);
  NimBLEServer* server = NimBLEDevice::createServer();

  NimBLEService* dis = server->createService(NimBLEUUID(TOPOROOM_DIS_UUID));
  dis->createCharacteristic(TOPOROOM_DIS_MANUFACTURER_UUID, NIMBLE_PROPERTY::READ)
      ->setValue("TopoRoom");
  dis->createCharacteristic(TOPOROOM_DIS_MODEL_UUID, NIMBLE_PROPERTY::READ)
      ->setValue(TOPOROOM_HUB_SKU);
  dis->createCharacteristic(TOPOROOM_DIS_FW_UUID, NIMBLE_PROPERTY::READ)
      ->setValue(TOPOROOM_HUB_FW_VERSION);
  dis->start();

  NimBLEService* svc = server->createService(TOPOROOM_GATT_SERVICE_UUID);
  svc->createCharacteristic(TOPOROOM_GATT_SKU_UUID, NIMBLE_PROPERTY::READ)
      ->setValue(TOPOROOM_HUB_SKU);
  svc->createCharacteristic(TOPOROOM_GATT_FW_UUID, NIMBLE_PROPERTY::READ)
      ->setValue(TOPOROOM_HUB_FW_VERSION);

  NimBLECharacteristic* cmd =
      svc->createCharacteristic(TOPOROOM_GATT_MEASURE_CMD_UUID, NIMBLE_PROPERTY::WRITE);
  cmd->setCallbacks(&g_measure_cb);

  g_length = svc->createCharacteristic(TOPOROOM_GATT_LENGTH_UUID, NIMBLE_PROPERTY::NOTIFY);
  g_battery =
      svc->createCharacteristic(TOPOROOM_GATT_BATTERY_UUID,
                                NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  uint8_t batt = TOPOROOM_HUB_BATTERY_UNKNOWN;
  g_battery->setValue(&batt, 1);

  g_status = svc->createCharacteristic(TOPOROOM_GATT_STATUS_UUID, NIMBLE_PROPERTY::READ);
  uint8_t idle = TOPOROOM_HUB_STATUS_OK;
  g_status->setValue(&idle, 1);

  svc->start();

  NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
  adv->addServiceUUID(TOPOROOM_GATT_SERVICE_UUID);
  adv->addServiceUUID(TOPOROOM_DIS_UUID);
  adv->setName(TOPOROOM_HUB_ADV_NAME);
  adv->setScanResponse(true);
  adv->start();
  Serial.println("GATT advertising TopoRoom Hub");
}

void loop() {
  if (!g_pending) {
    delay(5);
    return;
  }
  g_pending = false;
  const uint8_t opcode = g_opcode;
  const uint16_t timeout = g_timeout_ms;

  if (opcode == TOPOROOM_HUB_OP_STOP) {
    uart_laser_stop();
    notify_length(-1, TOPOROOM_HUB_STATUS_OK, TOPOROOM_HUB_SOURCE_INVALID);
    return;
  }
  if (opcode != TOPOROOM_HUB_OP_SINGLE) {
    notify_length(-1, TOPOROOM_HUB_STATUS_BAD_CMD, TOPOROOM_HUB_SOURCE_INVALID);
    return;
  }

  g_busy = true;
  const UartLaserResult meas = uart_laser_measure(timeout, LASER_DIST_SCALE);
  g_busy = false;

  if (!meas.ok) {
    const uint8_t st =
        (meas.err == 0xFFu) ? TOPOROOM_HUB_STATUS_TIMEOUT : TOPOROOM_HUB_STATUS_UART_ERROR;
    notify_length(-1, st, TOPOROOM_HUB_SOURCE_INVALID);
    Serial.printf("laser fail err=%u\n", meas.err);
    return;
  }
  notify_length(meas.length_mm, TOPOROOM_HUB_STATUS_OK, TOPOROOM_HUB_SOURCE_LASER);
  Serial.printf("laser %d mm\n", (int)meas.length_mm);
}
