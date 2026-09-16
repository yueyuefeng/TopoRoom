#include "toporoom/adapters/imu_adapters.hpp"

namespace toporoom::adapters {

ModuleImuAdapter::ModuleImuAdapter(ports::ImuSampleDTO sample) : sample_(sample) {}

ports::ImuSampleDTO ModuleImuAdapter::read_sample() { return sample_; }

PhoneImuAdapter::PhoneImuAdapter(ports::ImuSampleDTO sample) : sample_(sample) {}

ports::ImuSampleDTO PhoneImuAdapter::read_sample() { return sample_; }

ports::ImuSampleDTO MissingImuAdapter::read_sample() { return {}; }

}  // namespace toporoom::adapters
