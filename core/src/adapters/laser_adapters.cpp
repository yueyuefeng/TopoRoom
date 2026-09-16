#include "toporoom/adapters/laser_adapters.hpp"

#include <stdexcept>
#include <string>
#include <utility>

#include "toporoom/adapters/capture_transport_error.hpp"

namespace toporoom::adapters {
namespace {

ports::MeasureSample parse_laser_payload(const std::string& payload,
                                         const std::string& device_id) {
  if (payload.rfind("RF", 0) == 0) {
    throw CaptureTransportError(CaptureTransportError::Kind::Protocol,
                                "rf_ble is never a dimension source");
  }
  std::string number = payload;
  if (payload.rfind("LEN ", 0) == 0) number = payload.substr(4);
  ports::MeasureSample sample;
  try {
    sample.value_mm = std::stod(number);
  } catch (const std::exception&) {
    throw CaptureTransportError(CaptureTransportError::Kind::Protocol,
                                "unparseable laser payload");
  }
  sample.timestamp = 1;
  sample.source = "laser";
  sample.instrument_id = device_id;
  return sample;
}

}  // namespace

void FakeBleLaserTransport::add_device(ports::LaserDeviceProfile profile) {
  devices_.push_back(std::move(profile));
}

void FakeBleLaserTransport::enqueue_payload(std::string payload) {
  payloads_.push_back(std::move(payload));
}

void FakeBleLaserTransport::fail_connect() { connect_fails_ = true; }

void FakeBleLaserTransport::fail_read_timeout() { read_timeout_ = true; }

void FakeBleLaserTransport::fail_disconnected() { disconnected_ = true; }

std::vector<ports::LaserDeviceProfile> FakeBleLaserTransport::scan() { return devices_; }

void FakeBleLaserTransport::connect(const std::string& device_id) {
  if (connect_fails_) {
    throw CaptureTransportError(CaptureTransportError::Kind::Disconnected,
                                "BLE connect failed");
  }
  connected_ = true;
  connected_id_ = device_id;
}

std::optional<std::string> FakeBleLaserTransport::read_payload(int) {
  if (!connected_) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "laser not connected");
  }
  if (disconnected_) {
    connected_ = false;
    throw CaptureTransportError(CaptureTransportError::Kind::Disconnected,
                                "laser disconnected");
  }
  if (read_timeout_ || payloads_.empty()) {
    throw CaptureTransportError(CaptureTransportError::Kind::Timeout, "laser timeout");
  }
  auto payload = payloads_.front();
  payloads_.erase(payloads_.begin());
  return payload;
}

void FakeBleLaserTransport::disconnect() { connected_ = false; }

BluetoothLaserPort::BluetoothLaserPort(BleLaserTransport& transport)
    : transport_(transport) {}

std::vector<ports::LaserDeviceProfile> BluetoothLaserPort::discover() {
  return transport_.scan();
}

ports::LaserHandle BluetoothLaserPort::connect(const std::string& device_id) {
  transport_.connect(device_id);
  connected_ = true;
  device_id_ = device_id;
  return ports::LaserHandle{device_id};
}

ports::MeasureSample BluetoothLaserPort::read_length_mm() {
  if (!connected_) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "laser not connected");
  }
  const auto payload = transport_.read_payload(1000);
  if (!payload) {
    throw CaptureTransportError(CaptureTransportError::Kind::Timeout, "laser timeout");
  }
  return parse_laser_payload(*payload, device_id_);
}

void BluetoothLaserPort::disconnect() {
  transport_.disconnect();
  connected_ = false;
}

void ReplayLaserPort::enqueue(ports::MeasureSample sample) {
  queue_.push_back(std::move(sample));
}

std::vector<ports::LaserDeviceProfile> ReplayLaserPort::discover() {
  return {{"replay_laser", "Replay laser", "replay_sku", "laser"}};
}

ports::LaserHandle ReplayLaserPort::connect(const std::string& device_id) {
  connected_ = true;
  device_id_ = device_id;
  return ports::LaserHandle{device_id};
}

ports::MeasureSample ReplayLaserPort::read_length_mm() {
  if (!connected_) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "laser not connected");
  }
  if (queue_.empty()) {
    throw CaptureTransportError(CaptureTransportError::Kind::Timeout, "laser timeout");
  }
  auto sample = queue_.front();
  queue_.erase(queue_.begin());
  if (sample.instrument_id.empty()) sample.instrument_id = device_id_;
  if (sample.source.empty()) sample.source = "laser";
  return sample;
}

void ReplayLaserPort::disconnect() { connected_ = false; }

void TypedLaserPort::set_next(double value_mm) { next_mm_ = value_mm; }

std::vector<ports::LaserDeviceProfile> TypedLaserPort::discover() {
  return {{"typed", "Keyboard", "typed", "typed"}};
}

ports::LaserHandle TypedLaserPort::connect(const std::string& device_id) {
  connected_ = true;
  return ports::LaserHandle{device_id};
}

ports::MeasureSample TypedLaserPort::read_length_mm() {
  if (!connected_ || !next_mm_) {
    throw CaptureTransportError(CaptureTransportError::Kind::NotConnected,
                                "no typed value");
  }
  ports::MeasureSample sample;
  sample.value_mm = *next_mm_;
  sample.timestamp = 1;
  sample.source = "typed";
  sample.instrument_id = "typed";
  next_mm_.reset();
  return sample;
}

void TypedLaserPort::disconnect() { connected_ = false; }

}  // namespace toporoom::adapters
