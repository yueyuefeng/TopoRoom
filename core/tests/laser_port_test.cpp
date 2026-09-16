#include <optional>
#include <string>
#include <type_traits>

#include <gtest/gtest.h>

#include "toporoom/adapters/capture_transport_error.hpp"
#include "toporoom/adapters/fake_geometry_port.hpp"
#include "toporoom/adapters/in_memory_document_store.hpp"
#include "toporoom/adapters/laser_adapters.hpp"
#include "toporoom/adapters/recording_notify_port.hpp"
#include "toporoom/app/document_io.hpp"
#include "toporoom/app/laser_capture_service.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/kinds.hpp"
#include "toporoom/ports/laser_rangefinder_port.hpp"

using toporoom::adapters::BluetoothLaserPort;
using toporoom::adapters::CaptureTransportError;
using toporoom::adapters::FakeBleLaserTransport;
using toporoom::adapters::FakeGeometryPort;
using toporoom::adapters::InMemoryDocumentStore;
using toporoom::adapters::RecordingNotifyPort;
using toporoom::adapters::ReplayLaserPort;
using toporoom::adapters::TypedLaserPort;
using toporoom::app::GeometryRebuildPolicy;
using toporoom::app::LaserCaptureCommand;
using toporoom::app::LaserCaptureService;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::MeasurementSource;
using toporoom::ports::LaserDeviceProfile;

TEST(LaserPort, FakeBleConnectDisconnectStates) {
  FakeBleLaserTransport ble;
  ble.add_device({"dev_1", "Bosch GLM", "glm50", "laser"});
  BluetoothLaserPort laser(ble);
  EXPECT_FALSE(laser.connected());
  EXPECT_EQ(laser.discover().size(), 1u);
  laser.connect("dev_1");
  EXPECT_TRUE(laser.connected());
  EXPECT_TRUE(ble.connected());
  laser.disconnect();
  EXPECT_FALSE(laser.connected());
  EXPECT_THROW(laser.read_length_mm(), CaptureTransportError);
}

TEST(LaserPort, BluetoothMeasureIsLaserSource) {
  FakeBleLaserTransport ble;
  ble.add_device({"dev_1", "GLM", "glm50", "laser"});
  ble.enqueue_payload("LEN 900");
  BluetoothLaserPort laser(ble);
  laser.connect("dev_1");
  const auto sample = laser.read_length_mm();
  EXPECT_EQ(sample.source, "laser");
  EXPECT_EQ(sample.value_mm, 900);
  EXPECT_EQ(sample.instrument_id, "dev_1");
}

TEST(LaserPort, RfPayloadRejected) {
  FakeBleLaserTransport ble;
  ble.enqueue_payload("RF 1200");
  BluetoothLaserPort laser(ble);
  laser.connect("dev_1");
  EXPECT_THROW(laser.read_length_mm(), CaptureTransportError);
}

TEST(LaserCapture, MeasureWritesLaserIntoSceneIr) {
  InMemoryDocumentStore store;
  FakeGeometryPort geometry;
  GeometryRebuildPolicy rebuild(geometry);
  RecordingNotifyPort notify;
  ReplayLaserPort laser;
  laser.enqueue({900, 10, "laser", "laser_sku_x", std::nullopt});
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_laser"});
  store.save(doc.to_scene_ir());
  LaserCaptureService service(laser, store, rebuild, notify);
  LaserCaptureCommand command;
  command.document_id = "doc_laser";
  command.measurement_id = "m_door";
  command.device_id = "laser_sku_x";
  const auto result = service.capture(command);
  ASSERT_TRUE(result);
  const auto saved = store.load("doc_laser");
  ASSERT_TRUE(saved);
  ASSERT_FALSE(saved->measurements.empty());
  EXPECT_EQ(saved->measurements[0].source, MeasurementSource::Laser);
  EXPECT_EQ(saved->measurements[0].value_mm, 900);
  EXPECT_TRUE(notify.errors.empty());
}

TEST(LaserCapture, TimeoutNotifiesWithoutCorruptingDocument) {
  InMemoryDocumentStore store;
  FakeGeometryPort geometry;
  GeometryRebuildPolicy rebuild(geometry);
  RecordingNotifyPort notify;
  ReplayLaserPort laser;
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_laser"});
  store.save(doc.to_scene_ir());
  const int revision = store.load("doc_laser")->revision;
  LaserCaptureService service(laser, store, rebuild, notify);
  LaserCaptureCommand command;
  command.document_id = "doc_laser";
  command.measurement_id = "m_door";
  command.device_id = "laser_sku_x";
  EXPECT_EQ(service.capture(command), std::nullopt);
  EXPECT_FALSE(notify.errors.empty());
  EXPECT_EQ(store.load("doc_laser")->revision, revision);
  EXPECT_TRUE(store.load("doc_laser")->measurements.empty());
}

TEST(LaserPort, TypedFallbackMarksTyped) {
  TypedLaserPort typed;
  typed.set_next(2800);
  typed.connect("typed");
  const auto sample = typed.read_length_mm();
  EXPECT_EQ(sample.source, "typed");
  EXPECT_EQ(sample.value_mm, 2800);
}

TEST(Ports, LaserPortIsAbstract) {
  EXPECT_TRUE(std::is_abstract_v<toporoom::ports::LaserRangefinderPort>);
}
