#include "bmi270_stub.h"

#include <Arduino.h>
#include <Wire.h>

namespace {

int g_inited = 0;
int g_present = 0;
uint8_t g_chip_id = 0;

uint8_t try_read_chip_id() {
  Wire.beginTransmission(BMI270_I2C_ADDR);
  Wire.write(BMI270_REG_CHIP_ID);
  if (Wire.endTransmission(false) != 0) return 0;
  if (Wire.requestFrom(BMI270_I2C_ADDR, 1) != 1) return 0;
  return (uint8_t)Wire.read();
}

}  // namespace

void bmi270_stub_begin(int sda_pin, int scl_pin) {
  g_inited = 1;
  g_present = 0;
  g_chip_id = 0;
  Wire.begin(sda_pin, scl_pin);
  delay(5);
  const uint8_t id = try_read_chip_id();
  if (id == BMI270_CHIP_ID_EXPECTED) {
    g_chip_id = id;
    g_present = 1;
  }
}

int bmi270_stub_present(void) { return g_inited ? g_present : 0; }

uint8_t bmi270_stub_chip_id(void) { return g_chip_id; }
