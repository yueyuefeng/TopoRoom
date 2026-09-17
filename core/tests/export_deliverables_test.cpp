#include <cmath>
#include <cstdint>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include <gtest/gtest.h>

#include "toporoom/adapters/export_dxf.hpp"
#include "toporoom/adapters/export_glb.hpp"
#include "toporoom/adapters/export_pdf.hpp"
#include "toporoom/adapters/fake_geometry_port.hpp"
#include "toporoom/adapters/manifold_geometry_port.hpp"
#include "toporoom/adapters/scene_ir_json.hpp"
#include "toporoom/app/export_app_service.hpp"
#include "toporoom/app/status_gate.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/length_mm.hpp"
#include "toporoom/domain/point_mm.hpp"
#include "toporoom/ports/geometry_port.hpp"

#ifndef TOPOROOM_FIXTURE_DIR
#error TOPOROOM_FIXTURE_DIR is required
#endif
#ifndef TOPOROOM_REPO_DIR
#error TOPOROOM_REPO_DIR is required
#endif

using toporoom::adapters::export_dxf;
using toporoom::adapters::export_glb;
using toporoom::adapters::export_pdf;
using toporoom::adapters::FakeGeometryPort;
using toporoom::adapters::load_scene_ir_file;
using toporoom::adapters::ManifoldGeometryPort;
using toporoom::adapters::round_mm;
using toporoom::app::ExportAppService;
using toporoom::app::StatusGate;
using toporoom::domain::AddOpeningProps;
using toporoom::domain::AddWallProps;
using toporoom::domain::CloseRoomProps;
using toporoom::domain::CreateFloorPlanProps;
using toporoom::domain::FloorPlanDocument;
using toporoom::domain::LengthMm;
using toporoom::domain::OpeningKind;
using toporoom::domain::PointMm;
using toporoom::domain::SceneIR;
using toporoom::domain::WallKind;
using toporoom::ports::BuildRequest;
using toporoom::ports::FaultCode;
using toporoom::ports::semantics_from_scene_ir;

namespace {

std::string fixture_path() {
  return std::string(TOPOROOM_FIXTURE_DIR) + "/rect-room-door-laser.sceneir.json";
}

std::string repo_path(const std::string& relative) {
  return std::string(TOPOROOM_REPO_DIR) + "/" + relative;
}

std::string read_text(const std::string& path) {
  std::ifstream in(path);
  std::ostringstream buffer;
  buffer << in.rdbuf();
  return buffer.str();
}

std::vector<std::uint8_t> read_bytes(const std::string& path) {
  std::ifstream in(path, std::ios::binary);
  return {std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>()};
}

std::uint32_t le_u32(const std::vector<std::uint8_t>& bytes, std::size_t offset) {
  return static_cast<std::uint32_t>(bytes[offset]) |
         (static_cast<std::uint32_t>(bytes[offset + 1]) << 8) |
         (static_cast<std::uint32_t>(bytes[offset + 2]) << 16) |
         (static_cast<std::uint32_t>(bytes[offset + 3]) << 24);
}

SceneIR sample_scene() {
  auto doc = FloorPlanDocument::create(CreateFloorPlanProps{"doc_export_b"});
  const auto storey_id = doc.storeys()[0].id();
  auto add = [&](const char* id, double x0, double y0, double x1, double y1) {
    AddWallProps props;
    props.storey_id = storey_id;
    props.id = id;
    props.start = PointMm::of(x0, y0);
    props.end = PointMm::of(x1, y1);
    props.thickness = LengthMm::of(200);
    props.height = LengthMm::of(2800);
    props.kind = WallKind::Exterior;
    doc.add_wall(props);
  };
  add("wall_s", 0, 0, 4000, 0);
  AddOpeningProps opening;
  opening.storey_id = storey_id;
  opening.wall_id = "wall_s";
  opening.id = "op_door";
  opening.kind = OpeningKind::Door;
  opening.width = LengthMm::of(900);
  opening.height = LengthMm::of(2100);
  opening.offset_along_wall = LengthMm::of(800);
  doc.add_opening(opening);
  add("wall_e", 4000, 0, 4000, 3000);
  add("wall_n", 4000, 3000, 0, 3000);
  add("wall_w", 0, 3000, 0, 0);
  CloseRoomProps room;
  room.storey_id = storey_id;
  room.id = "room_living";
  room.wall_ids = {"wall_s", "wall_e", "wall_n", "wall_w"};
  doc.close_room(room);
  return doc.to_scene_ir();
}

bool bytes_contain(const std::vector<std::uint8_t>& bytes, const char* text) {
  const std::string haystack(bytes.begin(), bytes.end());
  return haystack.find(text) != std::string::npos;
}

}  // namespace

TEST(ExportGlb, MagicHeaderAndJsonChunk) {
  FakeGeometryPort geometry;
  const auto scene = sample_scene();
  BuildRequest request;
  request.semantics = semantics_from_scene_ir(scene);
  const auto rebuilt = geometry.rebuild(request);
  ASSERT_TRUE(rebuilt.ok);
  const auto glb = export_glb(scene, rebuilt.meshes);
  ASSERT_GE(glb.size(), 20u);
  EXPECT_EQ(glb[0], 'g');
  EXPECT_EQ(glb[1], 'l');
  EXPECT_EQ(glb[2], 'T');
  EXPECT_EQ(glb[3], 'F');
  EXPECT_EQ(le_u32(glb, 4), 2u);
  EXPECT_EQ(le_u32(glb, 8), static_cast<std::uint32_t>(glb.size()));
  EXPECT_EQ(le_u32(glb, 16), 0x4E4F534Au);  // JSON
  EXPECT_TRUE(bytes_contain(glb, "Wall_wall_s"));
  EXPECT_TRUE(bytes_contain(glb, "Storey_"));
  EXPECT_TRUE(bytes_contain(glb, "Opening_op_door"));
  EXPECT_TRUE(bytes_contain(glb, "Room_room_living"));
}

TEST(ExportGlb, PositionsAreMetresNotMillimetres) {
  ManifoldGeometryPort geometry;
  const auto scene = load_scene_ir_file(fixture_path());
  BuildRequest request;
  request.semantics = semantics_from_scene_ir(scene);
  const auto rebuilt = geometry.rebuild(request);
  ASSERT_TRUE(rebuilt.ok);
  const auto glb = export_glb(scene, rebuilt.meshes);
  const std::string as_text(glb.begin(), glb.end());
  EXPECT_NE(as_text.find("\"max\""), std::string::npos);
  // 4000 mm wall must appear as ~4 m, not thousands of metres.
  EXPECT_EQ(as_text.find("4000"), std::string::npos);
}

TEST(ExportDxf, LayersWallsOpeningsAndRoundedDimensions) {
  const auto scene = load_scene_ir_file(fixture_path());
  const auto dxf = export_dxf(scene);
  EXPECT_NE(dxf.find("0\nSECTION"), std::string::npos);
  EXPECT_NE(dxf.find("WALLS"), std::string::npos);
  EXPECT_NE(dxf.find("OPENINGS"), std::string::npos);
  EXPECT_NE(dxf.find("DIMS"), std::string::npos);
  EXPECT_NE(dxf.find("LINE"), std::string::npos);
  EXPECT_NE(dxf.find("wall_s"), std::string::npos);
  EXPECT_NE(dxf.find("op_door"), std::string::npos);
  EXPECT_NE(dxf.find("4000"), std::string::npos);
  EXPECT_NE(dxf.find("3000"), std::string::npos);
  EXPECT_NE(dxf.find(std::to_string(round_mm(900))), std::string::npos);
  EXPECT_NE(dxf.find("$INSUNITS"), std::string::npos);
}

TEST(ExportPdf, NonEmptyWithPlanMarkers) {
  const auto scene = load_scene_ir_file(fixture_path());
  const auto pdf = export_pdf(scene);
  ASSERT_GE(pdf.size(), 200u);
  ASSERT_EQ(pdf[0], '%');
  EXPECT_TRUE(bytes_contain(pdf, "%PDF-1."));
  EXPECT_TRUE(bytes_contain(pdf, "%%EOF"));
  EXPECT_TRUE(bytes_contain(pdf, "wall_s"));
  EXPECT_TRUE(bytes_contain(pdf, "op_door"));
  EXPECT_TRUE(bytes_contain(pdf, "4000"));
  EXPECT_TRUE(bytes_contain(pdf, "900"));
}

TEST(ExportAppService, FaultRejectsGlbAllowsSemanticDxf) {
  FakeGeometryPort geometry;
  geometry.fail_with({FaultCode::NotManifold, "broken boolean", {"wall_s"}});
  ExportAppService service(geometry);
  const auto outcome = service.export_scene_graph(sample_scene());
  EXPECT_FALSE(outcome.ok);
  EXPECT_EQ(outcome.fault.code, FaultCode::NotManifold);
  EXPECT_TRUE(outcome.glb.empty());
  EXPECT_NE(outcome.dxf.find("WALLS"), std::string::npos);
  EXPECT_FALSE(outcome.pdf.empty());
}

TEST(ExportAppService, OkPathProducesGlbDxfPdf) {
  FakeGeometryPort geometry;
  ExportAppService service(geometry);
  const auto outcome = service.export_scene_graph(load_scene_ir_file(fixture_path()));
  ASSERT_TRUE(outcome.ok) << outcome.fault.message;
  ASSERT_GE(outcome.glb.size(), 20u);
  EXPECT_EQ(outcome.glb[0], 'g');
  EXPECT_NE(outcome.dxf.find("WALLS"), std::string::npos);
  ASSERT_GE(outcome.pdf.size(), 200u);
  EXPECT_EQ(outcome.pdf[0], '%');
  StatusGate gate;
  toporoom::ports::RebuildResult rebuilt;
  rebuilt.ok = true;
  rebuilt.meshes = outcome.meshes;
  EXPECT_NO_THROW(gate.assert_exportable(rebuilt));
}

TEST(GodotSample, HostProjectKeepsGlbRoamReadOnly) {
  const auto project = read_text(repo_path("godot/project.godot"));
  EXPECT_NE(project.find("拓间 TopoRoom"), std::string::npos);
  EXPECT_NE(project.find("app/main.tscn"), std::string::npos);
  EXPECT_NE(project.find("toporoom.gdextension"), std::string::npos);
  EXPECT_EQ(project.find("save_dimension"), std::string::npos);

  const auto roam_script = read_text(repo_path("godot/app/roam.gd"));
  EXPECT_NE(roam_script.find("rect-room-door-laser.glb"), std::string::npos);
  EXPECT_NE(roam_script.find("GLTFDocument"), std::string::npos);
  EXPECT_EQ(roam_script.find("save_dimension"), std::string::npos);
  EXPECT_EQ(roam_script.find("add_wall"), std::string::npos);

  const auto ext = read_text(repo_path("godot/toporoom.gdextension"));
  EXPECT_NE(ext.find("toporoom_library_init"), std::string::npos);
  EXPECT_NE(ext.find("android.debug.arm64"), std::string::npos);

  const auto glb = read_bytes(repo_path("godot/fixtures/rect-room-door-laser.glb"));
  ASSERT_GE(glb.size(), 20u);
  EXPECT_EQ(glb[0], 'g');
  EXPECT_EQ(glb[1], 'l');
  EXPECT_EQ(glb[2], 'T');
  EXPECT_EQ(glb[3], 'F');
}
