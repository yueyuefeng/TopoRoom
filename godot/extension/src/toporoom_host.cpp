#include "toporoom_host.hpp"

#include <string>

using namespace godot;

namespace {

std::string to_utf8(const String& s) {
  const CharString cs = s.utf8();
  return cs.get_data() ? std::string(cs.get_data()) : std::string();
}

String from_utf8(const char* s) { return s ? String::utf8(s) : String(); }

const char* opt(const std::string& s) { return s.empty() ? nullptr : s.c_str(); }

}  // namespace

TopoRoomHost::TopoRoomHost() { ensure_guide(); }

TopoRoomHost::~TopoRoomHost() { reset(); }

void TopoRoomHost::ensure_guide() {
  if (!guide_) guide_ = toporoom_guide_create();
}

void TopoRoomHost::reset() {
  if (doc_) {
    toporoom_document_destroy(doc_);
    doc_ = nullptr;
  }
  if (guide_) {
    toporoom_guide_destroy(guide_);
    guide_ = nullptr;
  }
}

Dictionary TopoRoomHost::need_doc() const {
  Dictionary d;
  d["ok"] = false;
  d["error"] = "no document";
  return d;
}

Dictionary TopoRoomHost::from_rc(int rc, const char* err) const {
  Dictionary d;
  d["ok"] = rc == 0;
  d["error"] = rc == 0 ? String() : from_utf8(err && err[0] ? err : "error");
  return d;
}

Dictionary TopoRoomHost::adopt(TopoRoomDocument* next, const char* err) {
  if (!next) {
    Dictionary d;
    d["ok"] = false;
    d["error"] = from_utf8(err && err[0] ? err : "load failed");
    return d;
  }
  if (doc_) toporoom_document_destroy(doc_);
  doc_ = next;
  if (guide_) {
    toporoom_guide_destroy(guide_);
    guide_ = nullptr;
  }
  ensure_guide();
  Dictionary d;
  d["ok"] = true;
  d["error"] = "";
  d["id"] = document_id();
  d["storey_id"] = first_storey_id();
  return d;
}

String TopoRoomHost::version() const { return from_utf8(toporoom_version()); }

bool TopoRoomHost::has_document() const { return doc_ != nullptr; }

String TopoRoomHost::document_id() const {
  if (!doc_) return String();
  char buf[128] = {};
  if (toporoom_document_id(doc_, buf, sizeof(buf)) != 0) return String();
  return from_utf8(buf);
}

String TopoRoomHost::first_storey_id() const {
  if (!doc_) return String();
  char buf[128] = {};
  if (toporoom_document_first_storey_id(doc_, buf, sizeof(buf)) != 0) return String();
  return from_utf8(buf);
}

String TopoRoomHost::sceneir_json() const {
  if (!doc_) return String();
  char* json = toporoom_document_to_sceneir_json(doc_);
  if (!json) return String();
  String out = from_utf8(json);
  toporoom_string_free(json);
  return out;
}

Dictionary TopoRoomHost::create_document(const String& id) {
  const std::string cid = to_utf8(id);
  TopoRoomDocument* next = toporoom_document_create(cid.c_str());
  return adopt(next, next ? "" : "create failed");
}

Dictionary TopoRoomHost::load_json(const String& json) {
  const std::string text = to_utf8(json);
  char err[512] = {};
  TopoRoomDocument* next = toporoom_document_from_sceneir_json(text.c_str(), err, sizeof(err));
  return adopt(next, err);
}

Dictionary TopoRoomHost::load_file(const String& path) {
  const std::string p = to_utf8(path);
  char err[512] = {};
  TopoRoomDocument* next = toporoom_document_load(p.c_str(), err, sizeof(err));
  return adopt(next, err);
}

Dictionary TopoRoomHost::save_file(const String& path) {
  if (!doc_) return need_doc();
  const std::string p = to_utf8(path);
  char err[512] = {};
  const int rc = toporoom_document_save(doc_, p.c_str(), err, sizeof(err));
  return from_rc(rc, err);
}

void TopoRoomHost::destroy_document() {
  if (doc_) {
    toporoom_document_destroy(doc_);
    doc_ = nullptr;
  }
}

Dictionary TopoRoomHost::add_wall(const String& storey_id, const String& wall_id, double x0,
                                 double y0, double x1, double y1, double thickness_mm,
                                 double height_mm) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  char err[512] = {};
  const int rc = toporoom_document_add_wall(doc_, sid.c_str(), wid.c_str(), x0, y0, x1, y1,
                                            thickness_mm, height_mm, err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::move_wall(const String& storey_id, const String& wall_id, double x0,
                                  double y0, double x1, double y1) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  char err[512] = {};
  const int rc = toporoom_document_move_wall(doc_, sid.c_str(), wid.c_str(), x0, y0, x1, y1,
                                             err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::resize_wall(const String& storey_id, const String& wall_id,
                                    double length_mm) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  char err[512] = {};
  const int rc = toporoom_document_resize_wall(doc_, sid.c_str(), wid.c_str(), length_mm, err,
                                               sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::delete_wall(const String& storey_id, const String& wall_id) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  char err[512] = {};
  const int rc =
      toporoom_document_delete_wall(doc_, sid.c_str(), wid.c_str(), err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::set_wall_height(const String& storey_id, const String& wall_id,
                                         double height_mm) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  char err[512] = {};
  const int rc = toporoom_document_set_wall_height(doc_, sid.c_str(), wid.c_str(), height_mm,
                                                   err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::set_wall_kind(const String& storey_id, const String& wall_id,
                                       const String& kind) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  const std::string k = to_utf8(kind);
  char err[512] = {};
  const int rc =
      toporoom_document_set_wall_kind(doc_, sid.c_str(), wid.c_str(), k.c_str(), err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::demolish_wall(const String& storey_id, const String& wall_id,
                                       bool force) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  char err[512] = {};
  const int rc = toporoom_document_demolish_wall(doc_, sid.c_str(), wid.c_str(), force ? 1 : 0,
                                                 err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::split_wall(const String& storey_id, const String& wall_id,
                                    double offset_mm) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  char err[512] = {};
  char nid[128] = {};
  const int rc = toporoom_document_split_wall(doc_, sid.c_str(), wid.c_str(), offset_mm, nid,
                                              sizeof(nid), err, sizeof(err));
  Dictionary d = from_rc(rc, err);
  if (rc == 0) d["new_wall_id"] = from_utf8(nid);
  return d;
}

Dictionary TopoRoomHost::partial_demolish(const String& storey_id, const String& wall_id,
                                          double offset_mm, double length_mm, bool force) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  char err[512] = {};
  const int rc = toporoom_document_partial_demolish(doc_, sid.c_str(), wid.c_str(), offset_mm,
                                                    length_mm, force ? 1 : 0, err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::punch_opening(const String& storey_id, const String& wall_id,
                                       const String& opening_id, const String& kind,
                                       double width_mm, double height_mm, double offset_mm,
                                       double sill_height_mm, bool force) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  const std::string oid = to_utf8(opening_id);
  const std::string k = to_utf8(kind);
  char err[512] = {};
  const int rc = toporoom_document_punch_opening(
      doc_, sid.c_str(), wid.c_str(), oid.c_str(), k.c_str(), width_mm, height_mm, offset_mm,
      sill_height_mm, force ? 1 : 0, err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::import_fake_vision(const String& image_uri) {
  if (!doc_) return need_doc();
  const std::string uri = to_utf8(image_uri);
  char err[512] = {};
  const int rc =
      toporoom_document_import_fake_vision(doc_, uri.empty() ? nullptr : uri.c_str(), err,
                                           sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::import_vision_image(const String& path, double mm_per_px) {
  if (!doc_) return need_doc();
  const std::string p = to_utf8(path);
  char err[512] = {};
  TopoRoomVisionCounts counts{};
  const int rc =
      toporoom_vision_import_image_ex(doc_, p.c_str(), mm_per_px, &counts, err, sizeof(err));
  Dictionary d = from_rc(rc, err);
  d["wall_count"] = counts.wall_count;
  d["opening_count"] = counts.opening_count;
  d["shear_count"] = counts.shear_count;
  d["masonry_count"] = counts.masonry_count;
  d["door_count"] = counts.door_count;
  d["window_count"] = counts.window_count;
  d["mm_per_px"] = counts.mm_per_px;
  return d;
}

bool TopoRoomHost::vision_ml_available() const { return toporoom_vision_ml_available() != 0; }

Dictionary TopoRoomHost::add_opening(const String& storey_id, const String& wall_id,
                                    const String& opening_id, const String& kind,
                                    double width_mm, double height_mm, double offset_mm,
                                    double sill_height_mm) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string wid = to_utf8(wall_id);
  const std::string oid = to_utf8(opening_id);
  const std::string k = to_utf8(kind);
  char err[512] = {};
  const int rc = toporoom_document_add_opening(doc_, sid.c_str(), wid.c_str(), oid.c_str(),
                                               k.c_str(), width_mm, height_mm, offset_mm,
                                               sill_height_mm, err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::update_opening(const String& storey_id, const String& opening_id,
                                       const String& kind, double width_mm, double height_mm,
                                       double offset_mm, double sill_height_mm) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string oid = to_utf8(opening_id);
  const std::string k = to_utf8(kind);
  char err[512] = {};
  const int rc = toporoom_document_update_opening(doc_, sid.c_str(), oid.c_str(), k.c_str(),
                                                  width_mm, height_mm, offset_mm,
                                                  sill_height_mm, err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::delete_opening(const String& storey_id, const String& opening_id) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string oid = to_utf8(opening_id);
  char err[512] = {};
  const int rc =
      toporoom_document_delete_opening(doc_, sid.c_str(), oid.c_str(), err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::close_room(const String& storey_id, const String& room_id,
                                   const String& wall_ids_csv) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string rid = to_utf8(room_id);
  const std::string csv = to_utf8(wall_ids_csv);
  char err[512] = {};
  const int rc = toporoom_document_close_room(doc_, sid.c_str(), rid.c_str(), csv.c_str(),
                                              err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::set_room_attributes(const String& storey_id, const String& room_id,
                                            const String& name, const String& space_type,
                                            bool has_clear_height, double clear_height_mm) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string rid = to_utf8(room_id);
  const std::string n = to_utf8(name);
  const std::string st = to_utf8(space_type);
  char err[512] = {};
  const int rc = toporoom_document_set_room_attributes(
      doc_, sid.c_str(), rid.c_str(), n.c_str(), st.c_str(), has_clear_height ? 1 : 0,
      clear_height_mm, err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::set_storey_height(const String& storey_id, double height_mm,
                                          bool follow_matching_walls) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  char err[512] = {};
  const int rc = toporoom_document_set_storey_height(
      doc_, sid.c_str(), height_mm, follow_matching_walls ? 1 : 0, err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::place_hosted(const String& storey_id, const String& component_id,
                                     const String& kind, double z_bottom_mm, double depth_mm,
                                     const String& host_wall_id) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string cid = to_utf8(component_id);
  const std::string k = to_utf8(kind);
  const std::string host = to_utf8(host_wall_id);
  char err[512] = {};
  const int rc = toporoom_document_place_hosted(doc_, sid.c_str(), cid.c_str(), k.c_str(),
                                                z_bottom_mm, depth_mm, opt(host), err,
                                                sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::update_hosted(const String& storey_id, const String& component_id,
                                      const String& kind, double z_bottom_mm,
                                      double depth_mm, const String& host_wall_id) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string cid = to_utf8(component_id);
  const std::string k = to_utf8(kind);
  const std::string host = to_utf8(host_wall_id);
  char err[512] = {};
  const int rc = toporoom_document_update_hosted(doc_, sid.c_str(), cid.c_str(), k.c_str(),
                                                 z_bottom_mm, depth_mm, opt(host), err,
                                                 sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::delete_hosted(const String& storey_id, const String& component_id) {
  if (!doc_) return need_doc();
  const std::string sid = to_utf8(storey_id);
  const std::string cid = to_utf8(component_id);
  char err[512] = {};
  const int rc =
      toporoom_document_delete_hosted(doc_, sid.c_str(), cid.c_str(), err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::set_measurement(const String& measurement_id, double value_mm,
                                        const String& source, const String& instrument_id,
                                        const String& between_csv, const String& target_type,
                                        const String& target_id,
                                        const String& target_field) {
  if (!doc_) return need_doc();
  const std::string mid = to_utf8(measurement_id);
  const std::string src = to_utf8(source);
  const std::string inst = to_utf8(instrument_id);
  const std::string between = to_utf8(between_csv);
  const std::string ttype = to_utf8(target_type);
  const std::string tid = to_utf8(target_id);
  const std::string tfield = to_utf8(target_field);
  char err[512] = {};
  const int rc = toporoom_document_set_measurement(
      doc_, mid.c_str(), value_mm, src.c_str(), opt(inst), opt(between), opt(ttype),
      opt(tid), opt(tfield), err, sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::export_document(const String& format, const String& path) {
  if (!doc_) return need_doc();
  const std::string fmt = to_utf8(format);
  const std::string p = to_utf8(path);
  char err[512] = {};
  const int rc = toporoom_document_export(doc_, fmt.c_str(), p.c_str(), err, sizeof(err));
  Dictionary d = from_rc(rc, err);
  d["format"] = format;
  d["path"] = path;
  return d;
}

Dictionary TopoRoomHost::rebuild_status() {
  if (!doc_) return need_doc();
  char status[32] = {};
  char err[512] = {};
  const int rc =
      toporoom_document_rebuild_status(doc_, status, sizeof(status), err, sizeof(err));
  Dictionary d;
  d["ok"] = rc == 0;
  d["status"] = from_utf8(status);
  d["error"] = rc == 0 ? String() : from_utf8(err);
  return d;
}

Dictionary TopoRoomHost::fake_one_room(const String& out_dir) {
  if (!doc_) return need_doc();
  ensure_guide();
  const std::string dir = to_utf8(out_dir);
  char err[512] = {};
  const int rc =
      toporoom_debug_fake_one_room(doc_, guide_, dir.empty() ? nullptr : dir.c_str(), err,
                                   sizeof(err));
  return from_rc(rc, err);
}

Dictionary TopoRoomHost::run_guided_edit() {
  if (!doc_) return need_doc();
  ensure_guide();
  char err[512] = {};
  const int rc = toporoom_document_run_guided_edit(doc_, guide_, err, sizeof(err));
  return from_rc(rc, err);
}

void TopoRoomHost::guide_mark_host_ok(bool ok) {
  ensure_guide();
  toporoom_guide_mark_host_ok(guide_, ok ? 1 : 0);
}

void TopoRoomHost::guide_note_wall() {
  ensure_guide();
  toporoom_guide_note_wall(guide_);
}

void TopoRoomHost::guide_note_opening() {
  ensure_guide();
  toporoom_guide_note_opening(guide_);
}

void TopoRoomHost::guide_note_key(const String& source, bool typed_explicit) {
  ensure_guide();
  const std::string src = to_utf8(source);
  toporoom_guide_note_key_measurement(guide_, src.c_str(), typed_explicit ? 1 : 0);
}

void TopoRoomHost::guide_note_rebuild(bool ok) {
  ensure_guide();
  toporoom_guide_note_rebuild(guide_, ok ? 1 : 0);
}

Dictionary TopoRoomHost::guide_sync_from_document(bool rebuild_ok) {
  if (!doc_) return need_doc();
  ensure_guide();
  const int rc = toporoom_guide_sync_from_document(guide_, doc_, rebuild_ok ? 1 : 0);
  return from_rc(rc, rc == 0 ? "" : "sync failed");
}

String TopoRoomHost::guide_phase() const {
  return from_utf8(toporoom_guide_phase(guide_));
}

bool TopoRoomHost::guide_can_export() const { return toporoom_guide_can_export(guide_) != 0; }

String TopoRoomHost::guide_blocking_reason() const {
  return from_utf8(toporoom_guide_blocking_reason(guide_));
}

bool TopoRoomHost::whitelist_allows(const String& json, const String& phone_model,
                                    int android_api, const String& module_sku,
                                    const String& firmware, const String& hub_sku,
                                    const String& app_version) const {
  const std::string j = to_utf8(json);
  const std::string phone = to_utf8(phone_model);
  const std::string sku = to_utf8(module_sku);
  const std::string fw = to_utf8(firmware);
  const std::string hub = to_utf8(hub_sku);
  const std::string ver = to_utf8(app_version);
  return toporoom_whitelist_allows(j.c_str(), phone.c_str(), android_api, sku.c_str(),
                                   fw.c_str(), hub.c_str(), ver.c_str()) != 0;
}

void TopoRoomHost::_bind_methods() {
  ClassDB::bind_method(D_METHOD("version"), &TopoRoomHost::version);
  ClassDB::bind_method(D_METHOD("has_document"), &TopoRoomHost::has_document);
  ClassDB::bind_method(D_METHOD("document_id"), &TopoRoomHost::document_id);
  ClassDB::bind_method(D_METHOD("first_storey_id"), &TopoRoomHost::first_storey_id);
  ClassDB::bind_method(D_METHOD("sceneir_json"), &TopoRoomHost::sceneir_json);

  ClassDB::bind_method(D_METHOD("create_document", "id"), &TopoRoomHost::create_document);
  ClassDB::bind_method(D_METHOD("load_json", "json"), &TopoRoomHost::load_json);
  ClassDB::bind_method(D_METHOD("load_file", "path"), &TopoRoomHost::load_file);
  ClassDB::bind_method(D_METHOD("save_file", "path"), &TopoRoomHost::save_file);
  ClassDB::bind_method(D_METHOD("destroy_document"), &TopoRoomHost::destroy_document);

  ClassDB::bind_method(D_METHOD("add_wall", "storey_id", "wall_id", "x0", "y0", "x1", "y1",
                                 "thickness_mm", "height_mm"),
                       &TopoRoomHost::add_wall);
  ClassDB::bind_method(D_METHOD("move_wall", "storey_id", "wall_id", "x0", "y0", "x1", "y1"),
                       &TopoRoomHost::move_wall);
  ClassDB::bind_method(D_METHOD("resize_wall", "storey_id", "wall_id", "length_mm"),
                       &TopoRoomHost::resize_wall);
  ClassDB::bind_method(D_METHOD("delete_wall", "storey_id", "wall_id"),
                       &TopoRoomHost::delete_wall);
  ClassDB::bind_method(D_METHOD("set_wall_height", "storey_id", "wall_id", "height_mm"),
                       &TopoRoomHost::set_wall_height);
  ClassDB::bind_method(D_METHOD("set_wall_kind", "storey_id", "wall_id", "kind"),
                       &TopoRoomHost::set_wall_kind);
  ClassDB::bind_method(D_METHOD("demolish_wall", "storey_id", "wall_id", "force"),
                       &TopoRoomHost::demolish_wall);
  ClassDB::bind_method(D_METHOD("split_wall", "storey_id", "wall_id", "offset_mm"),
                       &TopoRoomHost::split_wall);
  ClassDB::bind_method(
      D_METHOD("partial_demolish", "storey_id", "wall_id", "offset_mm", "length_mm", "force"),
      &TopoRoomHost::partial_demolish);
  ClassDB::bind_method(
      D_METHOD("punch_opening", "storey_id", "wall_id", "opening_id", "kind", "width_mm",
               "height_mm", "offset_mm", "sill_height_mm", "force"),
      &TopoRoomHost::punch_opening);
  ClassDB::bind_method(D_METHOD("import_fake_vision", "image_uri"),
                       &TopoRoomHost::import_fake_vision);
  ClassDB::bind_method(D_METHOD("import_vision_image", "path", "mm_per_px"),
                       &TopoRoomHost::import_vision_image, DEFVAL(0.0));
  ClassDB::bind_method(D_METHOD("vision_ml_available"), &TopoRoomHost::vision_ml_available);

  ClassDB::bind_method(D_METHOD("add_opening", "storey_id", "wall_id", "opening_id", "kind",
                                 "width_mm", "height_mm", "offset_mm", "sill_height_mm"),
                       &TopoRoomHost::add_opening);
  ClassDB::bind_method(D_METHOD("update_opening", "storey_id", "opening_id", "kind",
                                 "width_mm", "height_mm", "offset_mm", "sill_height_mm"),
                       &TopoRoomHost::update_opening);
  ClassDB::bind_method(D_METHOD("delete_opening", "storey_id", "opening_id"),
                       &TopoRoomHost::delete_opening);

  ClassDB::bind_method(D_METHOD("close_room", "storey_id", "room_id", "wall_ids_csv"),
                       &TopoRoomHost::close_room);
  ClassDB::bind_method(
      D_METHOD("set_room_attributes", "storey_id", "room_id", "name", "space_type",
               "has_clear_height", "clear_height_mm"),
      &TopoRoomHost::set_room_attributes);
  ClassDB::bind_method(
      D_METHOD("set_storey_height", "storey_id", "height_mm", "follow_matching_walls"),
      &TopoRoomHost::set_storey_height);

  ClassDB::bind_method(D_METHOD("place_hosted", "storey_id", "component_id", "kind",
                                 "z_bottom_mm", "depth_mm", "host_wall_id"),
                       &TopoRoomHost::place_hosted);
  ClassDB::bind_method(D_METHOD("update_hosted", "storey_id", "component_id", "kind",
                                 "z_bottom_mm", "depth_mm", "host_wall_id"),
                       &TopoRoomHost::update_hosted);
  ClassDB::bind_method(D_METHOD("delete_hosted", "storey_id", "component_id"),
                       &TopoRoomHost::delete_hosted);

  ClassDB::bind_method(
      D_METHOD("set_measurement", "measurement_id", "value_mm", "source", "instrument_id",
               "between_csv", "target_type", "target_id", "target_field"),
      &TopoRoomHost::set_measurement);

  ClassDB::bind_method(D_METHOD("export_document", "format", "path"),
                       &TopoRoomHost::export_document);
  ClassDB::bind_method(D_METHOD("rebuild_status"), &TopoRoomHost::rebuild_status);
  ClassDB::bind_method(D_METHOD("fake_one_room", "out_dir"), &TopoRoomHost::fake_one_room);
  ClassDB::bind_method(D_METHOD("run_guided_edit"), &TopoRoomHost::run_guided_edit);

  ClassDB::bind_method(D_METHOD("guide_mark_host_ok", "ok"),
                       &TopoRoomHost::guide_mark_host_ok);
  ClassDB::bind_method(D_METHOD("guide_note_wall"), &TopoRoomHost::guide_note_wall);
  ClassDB::bind_method(D_METHOD("guide_note_opening"), &TopoRoomHost::guide_note_opening);
  ClassDB::bind_method(D_METHOD("guide_note_key", "source", "typed_explicit"),
                       &TopoRoomHost::guide_note_key);
  ClassDB::bind_method(D_METHOD("guide_note_rebuild", "ok"),
                       &TopoRoomHost::guide_note_rebuild);
  ClassDB::bind_method(D_METHOD("guide_sync_from_document", "rebuild_ok"),
                       &TopoRoomHost::guide_sync_from_document);
  ClassDB::bind_method(D_METHOD("guide_phase"), &TopoRoomHost::guide_phase);
  ClassDB::bind_method(D_METHOD("guide_can_export"), &TopoRoomHost::guide_can_export);
  ClassDB::bind_method(D_METHOD("guide_blocking_reason"),
                       &TopoRoomHost::guide_blocking_reason);

  ClassDB::bind_method(
      D_METHOD("whitelist_allows", "json", "phone_model", "android_api", "module_sku",
               "firmware", "hub_sku", "app_version"),
      &TopoRoomHost::whitelist_allows);
}
