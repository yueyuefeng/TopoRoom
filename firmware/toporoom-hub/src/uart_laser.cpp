#include "uart_laser.h"

#include "toporoom_hub_protocol.h"

#include <Arduino.h>

namespace {

HardwareSerial& laser_serial() {
  static HardwareSerial serial(1);
  return serial;
}

int g_en_pin = -1;
int g_sim = 0;

}  // namespace

void uart_laser_begin(uint32_t baud, int tx_pin, int rx_pin, int en_pin) {
  g_en_pin = en_pin;
  if (en_pin >= 0) {
    pinMode(en_pin, OUTPUT);
    digitalWrite(en_pin, HIGH);
  }
  laser_serial().begin(baud, SERIAL_8N1, rx_pin, tx_pin);
  delay(20);
  while (laser_serial().available()) {
    laser_serial().read();
  }
}

void uart_laser_set_sim(int enabled) { g_sim = enabled ? 1 : 0; }

void uart_laser_stop(void) {
  uint8_t stop[JRT_SINGLE_MEASURE_SIZE] = {0xAAu, 0x00u, 0x00u, 0x20u, 0x00u,
                                           0x02u, 0x00u, 0x00u, 0x22u};
  if (g_sim) return;
  laser_serial().write(stop, sizeof(stop));
}

UartLaserResult uart_laser_measure(uint32_t timeout_ms, int dist_scale) {
  UartLaserResult result;
  result.length_mm = -1;
  result.err = 0xFFu;
  result.ok = 0;

  if (g_sim) {
    result.length_mm = 1000;
    result.err = 0;
    result.ok = 1;
    delay(20);
    return result;
  }

  uint8_t cmd[JRT_SINGLE_MEASURE_SIZE];
  jrt_pack_single_measure(cmd);
  while (laser_serial().available()) {
    laser_serial().read();
  }
  laser_serial().write(cmd, sizeof(cmd));
  laser_serial().flush();

  uint8_t buf[JRT_RESULT_MIN_SIZE];
  size_t got = 0;
  const uint32_t start = millis();
  while (got < sizeof(buf) && (millis() - start) < timeout_ms) {
    if (laser_serial().available()) {
      buf[got++] = (uint8_t)laser_serial().read();
      if (got == 1 && buf[0] != JRT_FRAME_HEADER) {
        got = 0;
      }
    } else {
      delay(1);
    }
  }
  if (got < sizeof(buf)) {
    return result;
  }

  int32_t mm = -1;
  uint8_t err = 0xFFu;
  if (jrt_parse_result_mm(buf, sizeof(buf), &mm, &err, dist_scale) != 0) {
    return result;
  }
  result.err = err;
  result.length_mm = mm;
  result.ok = (err == 0 && mm >= 0) ? 1 : 0;
  return result;
}
