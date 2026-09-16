#include "toporoom/adapters/scene_ir_json.hpp"

#include <fstream>
#include <nlohmann/json.hpp>
#include <sstream>

#include "toporoom/domain/error.hpp"
#include "toporoom/domain/kinds.hpp"

namespace toporoom::adapters {
namespace {

domain::Measurement parse_measurement(const nlohmann::json& j) {
  domain::Measurement m;
  m.id = j.at("id").get<std::string>();
  m.kind = domain::MeasurementKind::Length;
  m.value_mm = j.at("valueMm").get<double>();
  const auto source = domain::measurement_source_from_string(j.at("source").get<std::string>());
  if (!source) {
    throw domain::DomainError("Unknown measurement source", "INVALID_MEASUREMENT_SOURCE");
  }
  m.source = *source;
  if (j.contains("instrumentId")) {
    m.instrument_id = j.at("instrumentId").get<std::string>();
  }
  if (j.contains("between")) {
    m.between = j.at("between").get<std::vector<std::string>>();
  }
  if (j.contains("target")) {
    domain::MeasurementTarget target;
    target.entity_type = j["target"].at("entityType").get<std::string>();
    target.entity_id = j["target"].at("entityId").get<std::string>();
    target.field = j["target"].at("field").get<std::string>();
    m.target = target;
  }
  return m;
}

domain::SceneIROpening parse_opening(const nlohmann::json& j) {
  domain::SceneIROpening o;
  o.id = j.at("id").get<std::string>();
  const auto kind = domain::opening_kind_from_string(j.at("kind").get<std::string>());
  if (!kind) throw domain::DomainError("Unknown opening kind", "INVALID_OPENING");
  o.kind = *kind;
  o.width_mm = j.at("widthMm").get<double>();
  o.height_mm = j.at("heightMm").get<double>();
  o.offset_mm = j.at("offsetMm").get<double>();
  o.sill_height_mm = j.at("sillHeightMm").get<double>();
  return o;
}

domain::SceneIRWall parse_wall(const nlohmann::json& j) {
  domain::SceneIRWall w;
  w.id = j.at("id").get<std::string>();
  const auto kind = domain::wall_kind_from_string(j.at("kind").get<std::string>());
  if (!kind) throw domain::DomainError("Unknown wall kind", "INVALID_WALL");
  w.kind = *kind;
  w.start = {j.at("start").at("x").get<double>(), j.at("start").at("y").get<double>()};
  w.end = {j.at("end").at("x").get<double>(), j.at("end").at("y").get<double>()};
  w.thickness_mm = j.at("thicknessMm").get<double>();
  w.height_mm = j.at("heightMm").get<double>();
  if (j.contains("openings")) {
    for (const auto& opening : j.at("openings")) {
      w.openings.push_back(parse_opening(opening));
    }
  }
  return w;
}

}  // namespace

std::vector<std::string> validate_scene_ir_json(const std::string& json_text) {
  std::vector<std::string> issues;
  nlohmann::json j;
  try {
    j = nlohmann::json::parse(json_text);
  } catch (const std::exception& e) {
    return {std::string("SceneIR must be JSON: ") + e.what()};
  }
  if (!j.is_object()) return {"SceneIR must be an object"};
  if (j.value("format", "") != domain::kSceneIrFormat) {
    issues.emplace_back(std::string("format must be ") + domain::kSceneIrFormat);
  }
  if (j.value("version", "") != domain::kSceneIrVersion) {
    issues.emplace_back(std::string("version must be ") + domain::kSceneIrVersion);
  }
  if (j.value("units", "") != domain::kSceneIrUnits) {
    issues.emplace_back("units must be mm");
  }
  if (!j.contains("id") || !j["id"].is_string() || j["id"].get<std::string>().empty()) {
    issues.emplace_back("id is required");
  }
  if (!j.contains("storeys") || !j["storeys"].is_array() || j["storeys"].empty()) {
    issues.emplace_back("at least one storey is required");
  }
  if (!j.contains("measurements") || !j["measurements"].is_array()) {
    issues.emplace_back("measurements must be an array");
  } else {
    for (const auto& m : j["measurements"]) {
      if (!m.is_object()) {
        issues.emplace_back("measurement must be an object");
        continue;
      }
      const auto source = m.value("source", "");
      if (!domain::is_measurement_source(source)) {
        issues.emplace_back(
            "measurement source must be one of laser|typed|depth_fit");
      }
    }
  }
  return issues;
}

domain::SceneIR load_scene_ir_json(const std::string& json_text) {
  const auto issues = validate_scene_ir_json(json_text);
  if (!issues.empty()) {
    std::ostringstream joined;
    for (std::size_t i = 0; i < issues.size(); ++i) {
      if (i) joined << '\n';
      joined << issues[i];
    }
    throw domain::DomainError(joined.str(), "INVALID_SCENEIR");
  }
  const auto j = nlohmann::json::parse(json_text);
  domain::SceneIR scene;
  scene.format = j.at("format").get<std::string>();
  scene.version = j.at("version").get<std::string>();
  scene.id = j.at("id").get<std::string>();
  scene.units = j.at("units").get<std::string>();
  scene.revision = j.value("revision", 0);
  for (const auto& storey_j : j.at("storeys")) {
    domain::SceneIRStorey storey;
    storey.id = storey_j.at("id").get<std::string>();
    storey.elevation_mm = storey_j.at("elevationMm").get<double>();
    storey.height_mm = storey_j.at("heightMm").get<double>();
    for (const auto& wall_j : storey_j.at("walls")) {
      storey.walls.push_back(parse_wall(wall_j));
    }
    if (storey_j.contains("rooms")) {
      for (const auto& room_j : storey_j.at("rooms")) {
        domain::SceneIRRoom room;
        room.id = room_j.at("id").get<std::string>();
        room.wall_ids = room_j.at("wallIds").get<std::vector<std::string>>();
        storey.rooms.push_back(std::move(room));
      }
    }
    scene.storeys.push_back(std::move(storey));
  }
  if (j.contains("measurements")) {
    for (const auto& m : j.at("measurements")) {
      scene.measurements.push_back(parse_measurement(m));
    }
  }
  return scene;
}

domain::SceneIR load_scene_ir_file(const std::string& path) {
  std::ifstream in(path);
  if (!in) {
    throw domain::DomainError("Cannot open SceneIR fixture: " + path, "INVALID_SCENEIR");
  }
  std::ostringstream buffer;
  buffer << in.rdbuf();
  return load_scene_ir_json(buffer.str());
}

std::string scene_ir_to_json(const domain::SceneIR& scene) {
  nlohmann::json storeys = nlohmann::json::array();
  for (const auto& storey : scene.storeys) {
    nlohmann::json walls = nlohmann::json::array();
    for (const auto& wall : storey.walls) {
      nlohmann::json openings = nlohmann::json::array();
      for (const auto& opening : wall.openings) {
        openings.push_back({{"id", opening.id},
                            {"kind", domain::to_string(opening.kind)},
                            {"widthMm", opening.width_mm},
                            {"heightMm", opening.height_mm},
                            {"offsetMm", opening.offset_mm},
                            {"sillHeightMm", opening.sill_height_mm}});
      }
      walls.push_back({{"id", wall.id},
                       {"kind", domain::to_string(wall.kind)},
                       {"start", {{"x", wall.start.x}, {"y", wall.start.y}}},
                       {"end", {{"x", wall.end.x}, {"y", wall.end.y}}},
                       {"thicknessMm", wall.thickness_mm},
                       {"heightMm", wall.height_mm},
                       {"openings", openings}});
    }
    nlohmann::json rooms = nlohmann::json::array();
    for (const auto& room : storey.rooms) {
      rooms.push_back({{"id", room.id}, {"wallIds", room.wall_ids}});
    }
    storeys.push_back({{"id", storey.id},
                       {"elevationMm", storey.elevation_mm},
                       {"heightMm", storey.height_mm},
                       {"walls", walls},
                       {"rooms", rooms}});
  }
  nlohmann::json measurements = nlohmann::json::array();
  for (const auto& m : scene.measurements) {
    nlohmann::json mj = {{"id", m.id},
                         {"kind", "length"},
                         {"valueMm", m.value_mm},
                         {"source", domain::to_string(m.source)}};
    if (m.instrument_id) mj["instrumentId"] = *m.instrument_id;
    if (!m.between.empty()) mj["between"] = m.between;
    if (m.target) {
      mj["target"] = {{"entityType", m.target->entity_type},
                      {"entityId", m.target->entity_id},
                      {"field", m.target->field}};
    }
    measurements.push_back(std::move(mj));
  }
  nlohmann::json root = {{"format", scene.format},
                         {"version", scene.version},
                         {"id", scene.id},
                         {"units", scene.units},
                         {"revision", scene.revision},
                         {"storeys", storeys},
                         {"measurements", measurements}};
  return root.dump(2);
}

}  // namespace toporoom::adapters
