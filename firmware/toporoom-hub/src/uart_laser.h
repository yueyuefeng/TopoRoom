#pragma once

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  int32_t length_mm;
  uint8_t err;
  int ok;
} UartLaserResult;

void uart_laser_begin(uint32_t baud, int tx_pin, int rx_pin, int en_pin);
void uart_laser_set_sim(int enabled);
UartLaserResult uart_laser_measure(uint32_t timeout_ms, int dist_scale);
void uart_laser_stop(void);

#ifdef __cplusplus
}
#endif
