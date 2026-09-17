#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "toporoom/ports/laser_rangefinder_port.hpp"

namespace toporoom::adapters {

class BleLaserTransport {
 public:
  virtual ~BleLaserTransport() = default;
  virtual std::vector<ports::LaserDeviceProfile> scan() = 0;
  virtual void connect(const std::string& device_id) = 0;
  virtual std::optional<std::string> read_payload(int timeout_ms) = 0;
  virtual void disconnect() = 0;
  /* Optional GATT write (TopoRoom measure command). Fake ignores. */
  virtual void write_command(const std::vector<std::uint8_t>& /*bytes*/) {}
};

class FakeBleLaserTransport : public BleLaserTransport {
 public:
  void add_device(ports::LaserDeviceProfile profile);
  void enqueue_payload(std::string payload);
  void fail_connect();
  void fail_read_timeout();
  void fail_disconnected();
  bool connected() const noexcept { return connected_; }

  std::vector<ports::LaserDeviceProfile> scan() override;
  void connect(const std::string& device_id) override;
  std::optional<std::string> read_payload(int timeout_ms) override;
  void disconnect() override;

 private:
  std::vector<ports::LaserDeviceProfile> devices_;
  std::vector<std::string> payloads_;
  bool connected_ = false;
  bool connect_fails_ = false;
  bool read_timeout_ = false;
  bool disconnected_ = false;
  std::string connected_id_;
};

class BluetoothLaserPort : public ports::LaserRangefinderPort {
 public:
  explicit BluetoothLaserPort(BleLaserTransport& transport);
  bool connected() const noexcept { return connected_; }

  std::vector<ports::LaserDeviceProfile> discover() override;
  ports::LaserHandle connect(const std::string& device_id) override;
  ports::MeasureSample read_length_mm() override;
  void disconnect() override;
  /* Pack + write TopoRoom measure command, then read notify (Fake uses queued payload). */
  ports::MeasureSample measure_once(int timeout_ms = 1000);

 private:
  BleLaserTransport& transport_;
  bool connected_ = false;
  std::string device_id_;
};

class ReplayLaserPort : public ports::LaserRangefinderPort {
 public:
  void enqueue(ports::MeasureSample sample);
  bool connected() const noexcept { return connected_; }

  std::vector<ports::LaserDeviceProfile> discover() override;
  ports::LaserHandle connect(const std::string& device_id) override;
  ports::MeasureSample read_length_mm() override;
  void disconnect() override;

 private:
  std::vector<ports::MeasureSample> queue_;
  bool connected_ = false;
  std::string device_id_;
};

class TypedLaserPort : public ports::LaserRangefinderPort {
 public:
  void set_next(double value_mm);
  std::vector<ports::LaserDeviceProfile> discover() override;
  ports::LaserHandle connect(const std::string& device_id) override;
  ports::MeasureSample read_length_mm() override;
  void disconnect() override;

 private:
  std::optional<double> next_mm_;
  bool connected_ = false;
};

}  // namespace toporoom::adapters
