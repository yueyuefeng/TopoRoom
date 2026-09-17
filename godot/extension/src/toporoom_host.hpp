#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

#include "toporoom/c_api/toporoom.h"

namespace godot {

// InteractionShell façade. All mutations go through the C API into SceneIR /
// FloorPlanDocument. Godot nodes and imported .glb meshes are never written
// back as dimensions (I1, I8).
class TopoRoomHost : public RefCounted {
  GDCLASS(TopoRoomHost, RefCounted)

 public:
  TopoRoomHost();
  ~TopoRoomHost() override;

  String version() const;
  bool has_document() const;
  String document_id() const;
  String first_storey_id() const;
  String sceneir_json() const;

  Dictionary create_document(const String& id);
  Dictionary load_json(const String& json);
  Dictionary load_file(const String& path);
  Dictionary save_file(const String& path);
  void destroy_document();

  Dictionary add_wall(const String& storey_id, const String& wall_id, double x0, double y0,
                      double x1, double y1, double thickness_mm, double height_mm);
  Dictionary move_wall(const String& storey_id, const String& wall_id, double x0, double y0,
                       double x1, double y1);
  Dictionary resize_wall(const String& storey_id, const String& wall_id, double length_mm);
  Dictionary delete_wall(const String& storey_id, const String& wall_id);
  Dictionary set_wall_height(const String& storey_id, const String& wall_id,
                             double height_mm);
  Dictionary set_wall_kind(const String& storey_id, const String& wall_id, const String& kind);
  Dictionary demolish_wall(const String& storey_id, const String& wall_id, bool force);
  Dictionary split_wall(const String& storey_id, const String& wall_id, double offset_mm);
  Dictionary partial_demolish(const String& storey_id, const String& wall_id,
                              double offset_mm, double length_mm, bool force);
  Dictionary punch_opening(const String& storey_id, const String& wall_id,
                           const String& opening_id, const String& kind, double width_mm,
                           double height_mm, double offset_mm, double sill_height_mm,
                           bool force);
  Dictionary import_fake_vision(const String& image_uri);
  bool vision_ml_available() const;

  Dictionary add_opening(const String& storey_id, const String& wall_id,
                         const String& opening_id, const String& kind, double width_mm,
                         double height_mm, double offset_mm, double sill_height_mm);
  Dictionary update_opening(const String& storey_id, const String& opening_id,
                            const String& kind, double width_mm, double height_mm,
                            double offset_mm, double sill_height_mm);
  Dictionary delete_opening(const String& storey_id, const String& opening_id);

  Dictionary close_room(const String& storey_id, const String& room_id,
                        const String& wall_ids_csv);
  Dictionary set_room_attributes(const String& storey_id, const String& room_id,
                                 const String& name, const String& space_type,
                                 bool has_clear_height, double clear_height_mm);
  Dictionary set_storey_height(const String& storey_id, double height_mm,
                               bool follow_matching_walls);

  Dictionary place_hosted(const String& storey_id, const String& component_id,
                          const String& kind, double z_bottom_mm, double depth_mm,
                          const String& host_wall_id);
  Dictionary update_hosted(const String& storey_id, const String& component_id,
                           const String& kind, double z_bottom_mm, double depth_mm,
                           const String& host_wall_id);
  Dictionary delete_hosted(const String& storey_id, const String& component_id);

  Dictionary set_measurement(const String& measurement_id, double value_mm,
                             const String& source, const String& instrument_id,
                             const String& between_csv, const String& target_type,
                             const String& target_id, const String& target_field);

  Dictionary export_document(const String& format, const String& path);
  Dictionary rebuild_status();
  Dictionary fake_one_room(const String& out_dir);
  Dictionary run_guided_edit();

  void guide_mark_host_ok(bool ok);
  void guide_note_wall();
  void guide_note_opening();
  void guide_note_key(const String& source, bool typed_explicit);
  void guide_note_rebuild(bool ok);
  Dictionary guide_sync_from_document(bool rebuild_ok);
  String guide_phase() const;
  bool guide_can_export() const;
  String guide_blocking_reason() const;

  bool whitelist_allows(const String& json, const String& phone_model, int android_api,
                        const String& module_sku, const String& firmware,
                        const String& hub_sku, const String& app_version) const;

 protected:
  static void _bind_methods();

 private:
  TopoRoomDocument* doc_ = nullptr;
  TopoRoomGuide* guide_ = nullptr;

  void ensure_guide();
  void reset();
  Dictionary need_doc() const;
  Dictionary from_rc(int rc, const char* err) const;
  Dictionary adopt(TopoRoomDocument* next, const char* err);
};

}  // namespace godot
