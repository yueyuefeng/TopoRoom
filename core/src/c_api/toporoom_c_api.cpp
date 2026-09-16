#include "toporoom/c_api/toporoom.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <new>
#include <string>

#include "toporoom/adapters/scene_ir_json.hpp"
#include "toporoom/domain/error.hpp"
#include "toporoom/domain/floor_plan_document.hpp"

struct TopoRoomDocument {
  toporoom::domain::FloorPlanDocument impl;
};

const char* toporoom_version(void) { return "0.1.0"; }

TopoRoomDocument* toporoom_document_create(const char* id) {
  if (!id) return nullptr;
  try {
    return new TopoRoomDocument{
        toporoom::domain::FloorPlanDocument::create(
            toporoom::domain::CreateFloorPlanProps{id})};
  } catch (...) {
    return nullptr;
  }
}

void toporoom_document_destroy(TopoRoomDocument* doc) { delete doc; }

int toporoom_document_add_wall(TopoRoomDocument* doc, const char* storey_id,
                               const char* wall_id, double x0, double y0, double x1,
                               double y1, double thickness_mm, double height_mm,
                               char* errbuf, int errbuf_len) {
  if (!doc || !storey_id) return 1;
  try {
    toporoom::domain::AddWallProps props;
    props.storey_id = storey_id;
    if (wall_id) props.id = std::string(wall_id);
    props.start = toporoom::domain::PointMm::of(x0, y0);
    props.end = toporoom::domain::PointMm::of(x1, y1);
    props.thickness = toporoom::domain::LengthMm::of(thickness_mm);
    props.height = toporoom::domain::LengthMm::of(height_mm);
    props.kind = toporoom::domain::WallKind::Exterior;
    doc->impl.add_wall(std::move(props));
    return 0;
  } catch (const std::exception& ex) {
    if (errbuf && errbuf_len > 0) {
      std::snprintf(errbuf, static_cast<std::size_t>(errbuf_len), "%s", ex.what());
    }
    return 2;
  }
}

char* toporoom_document_to_sceneir_json(TopoRoomDocument* doc) {
  if (!doc) return nullptr;
  try {
    const auto json = toporoom::adapters::scene_ir_to_json(doc->impl.to_scene_ir());
    char* out = static_cast<char*>(std::malloc(json.size() + 1));
    if (!out) return nullptr;
    std::memcpy(out, json.c_str(), json.size() + 1);
    return out;
  } catch (...) {
    return nullptr;
  }
}

void toporoom_string_free(char* s) { std::free(s); }
