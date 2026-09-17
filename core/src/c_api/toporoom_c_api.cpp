#include "toporoom/c_api/toporoom.h"

#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <optional>
#include <string>
#include <vector>

#include "toporoom/adapters/android_whitelist.hpp"
#include "toporoom/adapters/hub_gatt_codec.hpp"
#include "toporoom/adapters/manifold_geometry_port.hpp"
#include "toporoom/adapters/release_train.hpp"
#include "toporoom/adapters/scene_ir_json.hpp"
#include "toporoom/app/evidence_pack.hpp"
#include "toporoom/app/export_app_service.hpp"
#include "toporoom/app/guided_room_session.hpp"
#include "toporoom/domain/floor_plan_document.hpp"
#include "toporoom/domain/kinds.hpp"

struct TopoRoomDocument {
  toporoom::domain::FloorPlanDocument impl;
};

struct TopoRoomGuide {
  toporoom::app::GuidedRoomSession session;
  mutable std::string reason_cache;
};

struct TopoRoomEvidence {
  toporoom::app::EvidencePack pack;
  explicit TopoRoomEvidence(std::string document_id)
      : pack(std::move(document_id)) {}
};

namespace {

int write_error(char* errbuf, int errbuf_len, const char* message) {
  if (errbuf && errbuf_len > 0) {
    std::snprintf(errbuf, static_cast<std::size_t>(errbuf_len), "%s",
                  message ? message : "");
  }
  return 2;
}

std::vector<std::string> split_csv(const char* text) {
  std::vector<std::string> out;
  if (!text || !*text) return out;
  std::string cur;
  for (const char* p = text; *p; ++p) {
    if (*p == ',') {
      if (!cur.empty()) out.push_back(cur);
      cur.clear();
    } else if (*p != ' ') {
      cur.push_back(*p);
    }
  }
  if (!cur.empty()) out.push_back(cur);
  return out;
}

int write_bytes(const std::string& path, const std::uint8_t* data, std::size_t n) {
  std::ofstream out(path, std::ios::binary);
  if (!out) return 1;
  out.write(reinterpret_cast<const char*>(data), static_cast<std::streamsize>(n));
  return out.good() ? 0 : 1;
}

int write_text(const std::string& path, const std::string& text) {
  return write_bytes(path, reinterpret_cast<const std::uint8_t*>(text.data()),
                     text.size());
}

int export_document(toporoom::domain::FloorPlanDocument& impl, const char* format,
                    const char* path, char* errbuf, int errbuf_len) {
  if (!format || !path) return write_error(errbuf, errbuf_len, "format and path required");
  try {
    toporoom::adapters::ManifoldGeometryPort geometry;
    toporoom::app::ExportAppService exporter(geometry);
    const auto outcome = exporter.export_scene_graph(impl.to_scene_ir());
    if (!outcome.ok) {
      return write_error(errbuf, errbuf_len, outcome.fault.message.c_str());
    }
    int rc = 1;
    if (std::strcmp(format, "glb") == 0) {
      rc = write_bytes(path, outcome.glb.data(), outcome.glb.size());
    } else if (std::strcmp(format, "dxf") == 0) {
      rc = write_text(path, outcome.dxf);
    } else if (std::strcmp(format, "pdf") == 0) {
      rc = write_bytes(path, outcome.pdf.data(), outcome.pdf.size());
    } else {
      return write_error(errbuf, errbuf_len, "format must be glb, dxf, or pdf");
    }
    if (rc != 0) return write_error(errbuf, errbuf_len, "failed to write export file");
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

}  // namespace

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

int toporoom_document_first_storey_id(TopoRoomDocument* doc, char* out, int out_len) {
  if (!doc || !out || out_len <= 0) return 1;
  if (doc->impl.storeys().empty()) return write_error(out, out_len, "no storey");
  std::snprintf(out, static_cast<std::size_t>(out_len), "%s",
                doc->impl.storeys()[0].id().c_str());
  return 0;
}

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
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_add_opening(TopoRoomDocument* doc, const char* storey_id,
                                  const char* wall_id, const char* opening_id,
                                  const char* kind, double width_mm, double height_mm,
                                  double offset_mm, double sill_height_mm, char* errbuf,
                                  int errbuf_len) {
  if (!doc || !storey_id || !wall_id) return 1;
  try {
    toporoom::domain::AddOpeningProps props;
    props.storey_id = storey_id;
    props.wall_id = wall_id;
    if (opening_id) props.id = std::string(opening_id);
    const auto parsed = toporoom::domain::opening_kind_from_string(kind ? kind : "door");
    if (!parsed) return write_error(errbuf, errbuf_len, "unknown opening kind");
    props.kind = *parsed;
    props.width = toporoom::domain::LengthMm::of(width_mm);
    props.height = toporoom::domain::LengthMm::of(height_mm);
    props.offset_along_wall = toporoom::domain::LengthMm::of(offset_mm);
    props.sill_height = toporoom::domain::LengthMm::of(sill_height_mm);
    doc->impl.add_opening(std::move(props));
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_set_measurement(TopoRoomDocument* doc, const char* measurement_id,
                                      double value_mm, const char* source,
                                      const char* instrument_id, const char* between_csv,
                                      const char* target_entity_type,
                                      const char* target_entity_id,
                                      const char* target_field, char* errbuf,
                                      int errbuf_len) {
  if (!doc || !measurement_id || !source) return 1;
  try {
    const auto parsed = toporoom::domain::measurement_source_from_string(source);
    if (!parsed) return write_error(errbuf, errbuf_len, "unknown measurement source");
    toporoom::domain::SetMeasurementProps props;
    props.id = measurement_id;
    props.value = toporoom::domain::LengthMm::of(value_mm);
    props.source = *parsed;
    if (instrument_id && *instrument_id) props.instrument_id = std::string(instrument_id);
    props.between = split_csv(between_csv);
    if (target_entity_type && target_entity_id && target_field && *target_entity_type) {
      props.target = toporoom::domain::MeasurementTarget{target_entity_type, target_entity_id,
                                                         target_field};
    }
    doc->impl.set_measurement(std::move(props));
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_close_room(TopoRoomDocument* doc, const char* storey_id,
                                 const char* room_id, const char* wall_ids_csv,
                                 char* errbuf, int errbuf_len) {
  if (!doc || !storey_id || !room_id) return 1;
  try {
    toporoom::domain::CloseRoomProps props;
    props.storey_id = storey_id;
    props.id = room_id;
    props.wall_ids = split_csv(wall_ids_csv);
    doc->impl.close_room(std::move(props));
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_move_wall(TopoRoomDocument* doc, const char* storey_id,
                                const char* wall_id, double x0, double y0, double x1,
                                double y1, char* errbuf, int errbuf_len) {
  if (!doc || !storey_id || !wall_id) return 1;
  try {
    doc->impl.move_wall(storey_id, wall_id, toporoom::domain::PointMm::of(x0, y0),
                        toporoom::domain::PointMm::of(x1, y1));
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_resize_wall(TopoRoomDocument* doc, const char* storey_id,
                                  const char* wall_id, double length_mm, char* errbuf,
                                  int errbuf_len) {
  if (!doc || !storey_id || !wall_id) return 1;
  try {
    doc->impl.resize_wall(storey_id, wall_id, toporoom::domain::LengthMm::of(length_mm));
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_delete_wall(TopoRoomDocument* doc, const char* storey_id,
                                  const char* wall_id, char* errbuf, int errbuf_len) {
  if (!doc || !storey_id || !wall_id) return 1;
  try {
    doc->impl.delete_wall(storey_id, wall_id);
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_set_wall_height(TopoRoomDocument* doc, const char* storey_id,
                                      const char* wall_id, double height_mm, char* errbuf,
                                      int errbuf_len) {
  if (!doc || !storey_id || !wall_id) return 1;
  try {
    doc->impl.set_wall_height(storey_id, wall_id,
                              toporoom::domain::LengthMm::of(height_mm));
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_update_opening(TopoRoomDocument* doc, const char* storey_id,
                                     const char* opening_id, const char* kind,
                                     double width_mm, double height_mm, double offset_mm,
                                     double sill_height_mm, char* errbuf, int errbuf_len) {
  if (!doc || !storey_id || !opening_id) return 1;
  try {
    const auto parsed = toporoom::domain::opening_kind_from_string(kind ? kind : "");
    if (!parsed) return write_error(errbuf, errbuf_len, "OpeningKind required: door|window|archway");
    doc->impl.update_opening(storey_id, opening_id, *parsed,
                             toporoom::domain::LengthMm::of(width_mm),
                             toporoom::domain::LengthMm::of(height_mm),
                             toporoom::domain::LengthMm::of(offset_mm),
                             toporoom::domain::LengthMm::of(sill_height_mm));
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_delete_opening(TopoRoomDocument* doc, const char* storey_id,
                                     const char* opening_id, char* errbuf,
                                     int errbuf_len) {
  if (!doc || !storey_id || !opening_id) return 1;
  try {
    doc->impl.delete_opening(storey_id, opening_id);
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_set_room_attributes(TopoRoomDocument* doc, const char* storey_id,
                                          const char* room_id, const char* name,
                                          const char* space_type, int has_clear_height,
                                          double clear_height_mm, char* errbuf,
                                          int errbuf_len) {
  if (!doc || !storey_id || !room_id) return 1;
  try {
    const auto parsed =
        toporoom::domain::space_type_from_string(space_type ? space_type : "interior");
    if (!parsed) return write_error(errbuf, errbuf_len, "unknown space type");
    std::optional<toporoom::domain::LengthMm> clear;
    if (has_clear_height) clear = toporoom::domain::LengthMm::of(clear_height_mm);
    doc->impl.set_room_attributes(storey_id, room_id, name ? name : "", *parsed, clear);
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_set_storey_height(TopoRoomDocument* doc, const char* storey_id,
                                        double height_mm, int follow_matching_walls,
                                        char* errbuf, int errbuf_len) {
  if (!doc || !storey_id) return 1;
  try {
    doc->impl.set_storey_height(storey_id, toporoom::domain::LengthMm::of(height_mm),
                                follow_matching_walls != 0);
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_place_hosted(TopoRoomDocument* doc, const char* storey_id,
                                   const char* component_id, const char* kind,
                                   double z_bottom_mm, double depth_mm,
                                   const char* host_wall_id, char* errbuf,
                                   int errbuf_len) {
  if (!doc || !storey_id) return 1;
  try {
    const auto parsed = toporoom::domain::hosted_kind_from_string(kind ? kind : "");
    if (!parsed) return write_error(errbuf, errbuf_len, "HostedKind required: beam|column|flue");
    toporoom::domain::PlaceHostedComponentProps props;
    props.storey_id = storey_id;
    if (component_id && *component_id) props.id = std::string(component_id);
    props.kind = *parsed;
    props.z_bottom_mm = z_bottom_mm;
    props.depth_mm = depth_mm;
    if (host_wall_id && *host_wall_id) props.host_wall_id = std::string(host_wall_id);
    doc->impl.place_hosted_component(std::move(props));
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_update_hosted(TopoRoomDocument* doc, const char* storey_id,
                                    const char* component_id, const char* kind,
                                    double z_bottom_mm, double depth_mm,
                                    const char* host_wall_id, char* errbuf,
                                    int errbuf_len) {
  if (!doc || !storey_id || !component_id) return 1;
  try {
    const auto parsed = toporoom::domain::hosted_kind_from_string(kind ? kind : "");
    if (!parsed) return write_error(errbuf, errbuf_len, "HostedKind required: beam|column|flue");
    std::optional<std::string> host;
    if (host_wall_id && *host_wall_id) host = std::string(host_wall_id);
    doc->impl.update_hosted_component(storey_id, component_id, *parsed, z_bottom_mm,
                                      depth_mm, host);
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_delete_hosted(TopoRoomDocument* doc, const char* storey_id,
                                    const char* component_id, char* errbuf,
                                    int errbuf_len) {
  if (!doc || !storey_id || !component_id) return 1;
  try {
    doc->impl.delete_hosted_component(storey_id, component_id);
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

int toporoom_document_export(TopoRoomDocument* doc, const char* format, const char* path,
                             char* errbuf, int errbuf_len) {
  if (!doc) return 1;
  return export_document(doc->impl, format, path, errbuf, errbuf_len);
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

int toporoom_debug_fake_one_room(TopoRoomDocument* doc, TopoRoomGuide* guide,
                                 const char* out_dir, char* errbuf, int errbuf_len) {
  if (!doc) return 1;
  if (!doc->impl.storeys().empty() && !doc->impl.storeys()[0].walls().empty()) {
    return write_error(errbuf, errbuf_len, "document already has walls");
  }
  try {
    const std::string storey_id = doc->impl.storeys()[0].id();
    auto add_wall = [&](const char* id, double x0, double y0, double x1, double y1) {
      toporoom::domain::AddWallProps props;
      props.storey_id = storey_id;
      props.id = id;
      props.start = toporoom::domain::PointMm::of(x0, y0);
      props.end = toporoom::domain::PointMm::of(x1, y1);
      props.thickness = toporoom::domain::LengthMm::of(200);
      props.height = toporoom::domain::LengthMm::of(2800);
      props.kind = toporoom::domain::WallKind::Exterior;
      doc->impl.add_wall(std::move(props));
    };
    add_wall("wall_n", 0, 3000, 4000, 3000);
    add_wall("wall_e", 4000, 3000, 4000, 0);
    add_wall("wall_s", 4000, 0, 0, 0);
    add_wall("wall_w", 0, 0, 0, 3000);

    toporoom::domain::AddOpeningProps opening;
    opening.storey_id = storey_id;
    opening.wall_id = "wall_s";
    opening.id = "op_door";
    opening.kind = toporoom::domain::OpeningKind::Door;
    opening.width = toporoom::domain::LengthMm::of(900);
    opening.height = toporoom::domain::LengthMm::of(2100);
    opening.offset_along_wall = toporoom::domain::LengthMm::of(800);
    doc->impl.add_opening(std::move(opening));

    toporoom::domain::SetMeasurementProps m_s;
    m_s.id = "m_key_s";
    m_s.value = toporoom::domain::LengthMm::of(4000);
    m_s.source = toporoom::domain::MeasurementSource::Laser;
    m_s.instrument_id = "fake_laser";
    m_s.between = {"wall_s"};
    doc->impl.set_measurement(m_s);

    toporoom::domain::SetMeasurementProps m_e;
    m_e.id = "m_key_e";
    m_e.value = toporoom::domain::LengthMm::of(3000);
    m_e.source = toporoom::domain::MeasurementSource::Laser;
    m_e.instrument_id = "fake_laser";
    m_e.between = {"wall_e"};
    doc->impl.set_measurement(m_e);

    toporoom::domain::CloseRoomProps room;
    room.storey_id = storey_id;
    room.id = "room_1";
    room.wall_ids = {"wall_n", "wall_e", "wall_s", "wall_w"};
    doc->impl.close_room(std::move(room));

    if (out_dir && *out_dir) {
      std::filesystem::create_directories(out_dir);
      const std::string dir(out_dir);
      const auto glb = dir + "/room.glb";
      const auto dxf = dir + "/room.dxf";
      const auto pdf = dir + "/room.pdf";
      if (export_document(doc->impl, "glb", glb.c_str(), errbuf, errbuf_len) != 0) return 2;
      if (export_document(doc->impl, "dxf", dxf.c_str(), errbuf, errbuf_len) != 0) return 2;
      if (export_document(doc->impl, "pdf", pdf.c_str(), errbuf, errbuf_len) != 0) return 2;
    }

    if (guide) {
      guide->session.mark_host_ok(true);
      for (int i = 0; i < 4; ++i) guide->session.note_wall();
      guide->session.note_key_measurement(toporoom::domain::MeasurementSource::Laser, false);
      guide->session.note_key_measurement(toporoom::domain::MeasurementSource::Laser, false);
      guide->session.note_opening();
      guide->session.note_rebuild(true);
    }
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

TopoRoomGuide* toporoom_guide_create(void) {
  try {
    return new TopoRoomGuide{};
  } catch (...) {
    return nullptr;
  }
}

void toporoom_guide_destroy(TopoRoomGuide* guide) { delete guide; }

void toporoom_guide_mark_host_ok(TopoRoomGuide* guide, int ok) {
  if (guide) guide->session.mark_host_ok(ok != 0);
}

void toporoom_guide_note_wall(TopoRoomGuide* guide) {
  if (guide) guide->session.note_wall();
}

void toporoom_guide_note_opening(TopoRoomGuide* guide) {
  if (guide) guide->session.note_opening();
}

void toporoom_guide_note_key_measurement(TopoRoomGuide* guide, const char* source,
                                         int typed_explicit) {
  if (!guide) return;
  const auto parsed =
      toporoom::domain::measurement_source_from_string(source ? source : "");
  if (!parsed) return;
  guide->session.note_key_measurement(*parsed, typed_explicit != 0);
}

void toporoom_guide_note_rebuild(TopoRoomGuide* guide, int ok) {
  if (guide) guide->session.note_rebuild(ok != 0);
}

const char* toporoom_guide_phase(const TopoRoomGuide* guide) {
  if (!guide) return "host_check";
  return toporoom::app::to_string(guide->session.phase());
}

int toporoom_guide_can_export(const TopoRoomGuide* guide) {
  return guide && guide->session.can_export() ? 1 : 0;
}

const char* toporoom_guide_blocking_reason(const TopoRoomGuide* guide) {
  if (!guide) return "no guide";
  guide->reason_cache = guide->session.blocking_reason();
  return guide->reason_cache.c_str();
}

int toporoom_guide_sync_from_document(TopoRoomGuide* guide, TopoRoomDocument* doc,
                                      int rebuild_ok) {
  if (!guide || !doc) return 1;
  guide->session.observe_scene(doc->impl.to_scene_ir(), rebuild_ok != 0);
  return 0;
}

int toporoom_document_run_guided_edit(TopoRoomDocument* doc, TopoRoomGuide* guide,
                                      char* errbuf, int errbuf_len) {
  if (!doc) return 1;
  if (!doc->impl.storeys().empty() && !doc->impl.storeys()[0].walls().empty()) {
    return write_error(errbuf, errbuf_len, "document already has walls");
  }
  try {
    const std::string storey_id = doc->impl.storeys()[0].id();
    auto add_wall = [&](const char* id, double x0, double y0, double x1, double y1) {
      toporoom::domain::AddWallProps props;
      props.storey_id = storey_id;
      props.id = id;
      props.start = toporoom::domain::PointMm::of(x0, y0);
      props.end = toporoom::domain::PointMm::of(x1, y1);
      props.thickness = toporoom::domain::LengthMm::of(200);
      props.height = toporoom::domain::LengthMm::of(2800);
      props.kind = toporoom::domain::WallKind::Exterior;
      doc->impl.add_wall(std::move(props));
    };
    add_wall("wall_n", 0, 3000, 4000, 3000);
    add_wall("wall_e", 4000, 3000, 4000, 0);
    add_wall("wall_s", 4000, 0, 0, 0);
    add_wall("wall_w", 0, 0, 0, 3000);

    toporoom::domain::AddOpeningProps opening;
    opening.storey_id = storey_id;
    opening.wall_id = "wall_s";
    opening.id = "op_arch";
    opening.kind = toporoom::domain::OpeningKind::Archway;
    opening.width = toporoom::domain::LengthMm::of(1200);
    opening.height = toporoom::domain::LengthMm::of(2100);
    opening.offset_along_wall = toporoom::domain::LengthMm::of(800);
    doc->impl.add_opening(std::move(opening));

    toporoom::domain::SetMeasurementProps m_s;
    m_s.id = "m_key_s";
    m_s.value = toporoom::domain::LengthMm::of(4000);
    m_s.source = toporoom::domain::MeasurementSource::Laser;
    m_s.instrument_id = "laser";
    m_s.between = {"wall_s"};
    doc->impl.set_measurement(m_s);

    toporoom::domain::SetMeasurementProps m_e;
    m_e.id = "m_key_e";
    m_e.value = toporoom::domain::LengthMm::of(3000);
    m_e.source = toporoom::domain::MeasurementSource::Laser;
    m_e.instrument_id = "laser";
    m_e.between = {"wall_e"};
    doc->impl.set_measurement(m_e);

    toporoom::domain::CloseRoomProps room;
    room.storey_id = storey_id;
    room.id = "room_1";
    room.name = "客厅";
    room.space_type = toporoom::domain::SpaceType::Interior;
    room.clear_height = toporoom::domain::LengthMm::of(2650);
    room.wall_ids = {"wall_n", "wall_e", "wall_s", "wall_w"};
    doc->impl.close_room(std::move(room));

    if (guide) {
      guide->session.mark_host_ok(true);
      guide->session.observe_scene(doc->impl.to_scene_ir(), true);
    }
    return 0;
  } catch (const std::exception& ex) {
    return write_error(errbuf, errbuf_len, ex.what());
  }
}

TopoRoomEvidence* toporoom_evidence_create(const char* document_id) {
  if (!document_id) return nullptr;
  try {
    return new TopoRoomEvidence(document_id);
  } catch (...) {
    return nullptr;
  }
}

void toporoom_evidence_destroy(TopoRoomEvidence* pack) { delete pack; }

int toporoom_evidence_empty(const TopoRoomEvidence* pack) {
  return !pack || pack->pack.empty() ? 1 : 0;
}

int toporoom_evidence_attach(TopoRoomEvidence* pack, const char* id, const char* kind,
                             const char* uri) {
  if (!pack || !id) return 1;
  pack->pack.attach({id, kind ? kind : "", uri ? uri : ""});
  return 0;
}

int toporoom_evidence_detach(TopoRoomEvidence* pack, const char* id) {
  if (!pack || !id) return 0;
  return pack->pack.detach(id) ? 1 : 0;
}

void toporoom_evidence_detach_all(TopoRoomEvidence* pack) {
  if (pack) pack->pack.detach_all();
}

int toporoom_whitelist_allows(const char* json_text, const char* phone_model,
                              int android_api, const char* module_sku,
                              const char* firmware, const char* hub_sku,
                              const char* app_version) {
  if (!json_text || !phone_model || !module_sku || !firmware || !hub_sku || !app_version) {
    return 0;
  }
  try {
    const auto table = toporoom::adapters::AndroidWhitelist::from_json(json_text);
    toporoom::adapters::WhitelistQuery query;
    query.phone_model = phone_model;
    query.android_api = android_api;
    query.module_sku = module_sku;
    query.firmware = firmware;
    query.hub_sku = hub_sku;
    query.app_version = app_version;
    return table.allows(query) ? 1 : 0;
  } catch (...) {
    return 0;
  }
}

int toporoom_ios_external_depth_in_p0(void) { return 0; }

int toporoom_release_train_matches(const char* json_text, const char* software_tag,
                                   const char* module_sku, const char* firmware,
                                   int whitelist_version, const char* hub_firmware) {
  if (!json_text || !software_tag || !module_sku || !firmware) return 0;
  try {
    const auto train = toporoom::adapters::load_release_train_json(json_text);
    return toporoom::adapters::release_train_matches(train, software_tag, module_sku,
                                                     firmware, whitelist_version,
                                                     hub_firmware ? hub_firmware : "")
               ? 1
               : 0;
  } catch (...) {
    return 0;
  }
}

int toporoom_hub_pack_measure_cmd(unsigned char* out, int out_len, unsigned timeout_ms) {
  if (!out || out_len < static_cast<int>(toporoom::adapters::HubGattCodec::kCmdSize)) {
    return -1;
  }
  const auto packed = toporoom::adapters::HubGattCodec::pack_measure_cmd(
      toporoom::adapters::kHubOpSingle, toporoom::adapters::kHubFlagRequireLaser,
      static_cast<uint16_t>(timeout_ms == 0 ? 1000 : timeout_ms));
  memcpy(out, packed.data(), packed.size());
  return 0;
}

int toporoom_hub_parse_length_notify_mm(const unsigned char* in, int len, double* out_mm) {
  if (!in || !out_mm || len < 0) return -1;
  try {
    const std::string payload(reinterpret_cast<const char*>(in), static_cast<std::size_t>(len));
    const auto sample = toporoom::adapters::HubGattCodec::parse_laser_payload(payload, "hub");
    *out_mm = sample.value_mm;
    return 0;
  } catch (...) {
    return -1;
  }
}
