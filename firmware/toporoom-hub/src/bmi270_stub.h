#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define BMI270_I2C_ADDR 0x68
#define BMI270_REG_CHIP_ID 0x00
#define BMI270_CHIP_ID_EXPECTED 0x24
#define BMI270_REG_PWR_CTRL 0x7D
#define BMI270_REG_CMD 0x7E

void bmi270_stub_begin(int sda_pin, int scl_pin);
int bmi270_stub_present(void);
uint8_t bmi270_stub_chip_id(void);

#ifdef __cplusplus
}
#endif
