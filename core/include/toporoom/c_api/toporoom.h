#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct TopoRoomDocument TopoRoomDocument;
typedef struct TopoRoomGuide TopoRoomGuide;
typedef struct TopoRoomEvidence TopoRoomEvidence;

const char* toporoom_version(void);

/* --- FloorPlanDocument --- */

TopoRoomDocument* toporoom_document_create(const char* id);
void toporoom_document_destroy(TopoRoomDocument* doc);

/* Copies the document id. Returns 0 on success. */
int toporoom_document_id(const TopoRoomDocument* doc, char* out, int out_len);

/* Copies the first storey id. Returns 0 on success. */
int toporoom_document_first_storey_id(TopoRoomDocument* doc, char* out, int out_len);

/* Returns 0 on success. Error message (if any) is written to errbuf. */
int toporoom_document_add_wall(TopoRoomDocument* doc, const char* storey_id,
                               const char* wall_id, double x0, double y0, double x1,
                               double y1, double thickness_mm, double height_mm,
                               char* errbuf, int errbuf_len);

/* kind: "door" | "window" | "archway" (门洞/窗洞/垭口). */
int toporoom_document_add_opening(TopoRoomDocument* doc, const char* storey_id,
                                  const char* wall_id, const char* opening_id,
                                  const char* kind, double width_mm, double height_mm,
                                  double offset_mm, double sill_height_mm, char* errbuf,
                                  int errbuf_len);

int toporoom_document_move_wall(TopoRoomDocument* doc, const char* storey_id,
                                const char* wall_id, double x0, double y0, double x1,
                                double y1, char* errbuf, int errbuf_len);

int toporoom_document_resize_wall(TopoRoomDocument* doc, const char* storey_id,
                                  const char* wall_id, double length_mm, char* errbuf,
                                  int errbuf_len);

int toporoom_document_delete_wall(TopoRoomDocument* doc, const char* storey_id,
                                  const char* wall_id, char* errbuf, int errbuf_len);

int toporoom_document_set_wall_height(TopoRoomDocument* doc, const char* storey_id,
                                      const char* wall_id, double height_mm, char* errbuf,
                                      int errbuf_len);

/* kind: "shearWall" | "masonry" | "partition" | "exterior" | "interior". */
int toporoom_document_set_wall_kind(TopoRoomDocument* doc, const char* storey_id,
                                    const char* wall_id, const char* kind, char* errbuf,
                                    int errbuf_len);

/* Full 拆除. force!=0 required for shearWall. */
int toporoom_document_demolish_wall(TopoRoomDocument* doc, const char* storey_id,
                                    const char* wall_id, int force, char* errbuf,
                                    int errbuf_len);

int toporoom_document_split_wall(TopoRoomDocument* doc, const char* storey_id,
                                 const char* wall_id, double offset_mm, char* new_id_out,
                                 int new_id_len, char* errbuf, int errbuf_len);

int toporoom_document_partial_demolish(TopoRoomDocument* doc, const char* storey_id,
                                       const char* wall_id, double offset_mm,
                                       double length_mm, int force, char* errbuf,
                                       int errbuf_len);

int toporoom_document_punch_opening(TopoRoomDocument* doc, const char* storey_id,
                                    const char* wall_id, const char* opening_id,
                                    const char* kind, double width_mm, double height_mm,
                                    double offset_mm, double sill_height_mm, int force,
                                    char* errbuf, int errbuf_len);

/* FakeVisionAdapter → add_wall with WallKind. image_uri may be empty. */
int toporoom_document_import_fake_vision(TopoRoomDocument* doc, const char* image_uri,
                                         char* errbuf, int errbuf_len);

/* Always 0 until on-device ML is linked. */
int toporoom_vision_ml_available(void);

int toporoom_document_update_opening(TopoRoomDocument* doc, const char* storey_id,
                                     const char* opening_id, const char* kind,
                                     double width_mm, double height_mm, double offset_mm,
                                     double sill_height_mm, char* errbuf, int errbuf_len);

int toporoom_document_delete_opening(TopoRoomDocument* doc, const char* storey_id,
                                     const char* opening_id, char* errbuf, int errbuf_len);

/* space_type: "interior" | "balcony" | "exterior". has_clear_height=0 omits 净高. */
int toporoom_document_set_room_attributes(TopoRoomDocument* doc, const char* storey_id,
                                          const char* room_id, const char* name,
                                          const char* space_type, int has_clear_height,
                                          double clear_height_mm, char* errbuf,
                                          int errbuf_len);

int toporoom_document_set_storey_height(TopoRoomDocument* doc, const char* storey_id,
                                        double height_mm, int follow_matching_walls,
                                        char* errbuf, int errbuf_len);

/* kind: "beam" | "column" | "flue". host_wall_id may be NULL (storey-level). */
int toporoom_document_place_hosted(TopoRoomDocument* doc, const char* storey_id,
                                   const char* component_id, const char* kind,
                                   double z_bottom_mm, double depth_mm,
                                   const char* host_wall_id, char* errbuf,
                                   int errbuf_len);

int toporoom_document_update_hosted(TopoRoomDocument* doc, const char* storey_id,
                                    const char* component_id, const char* kind,
                                    double z_bottom_mm, double depth_mm,
                                    const char* host_wall_id, char* errbuf,
                                    int errbuf_len);

int toporoom_document_delete_hosted(TopoRoomDocument* doc, const char* storey_id,
                                    const char* component_id, char* errbuf,
                                    int errbuf_len);

/* source: "laser" | "typed" | "depth_fit". between_csv / target_* may be NULL. */
int toporoom_document_set_measurement(TopoRoomDocument* doc, const char* measurement_id,
                                      double value_mm, const char* source,
                                      const char* instrument_id, const char* between_csv,
                                      const char* target_entity_type,
                                      const char* target_entity_id,
                                      const char* target_field, char* errbuf,
                                      int errbuf_len);

/* wall_ids_csv: "wall_n,wall_e,wall_s,wall_w" */
int toporoom_document_close_room(TopoRoomDocument* doc, const char* storey_id,
                                 const char* room_id, const char* wall_ids_csv,
                                 char* errbuf, int errbuf_len);

/* format: "glb" | "dxf" | "pdf". Uses ManifoldGeometryPort + StatusGate. */
int toporoom_document_export(TopoRoomDocument* doc, const char* format, const char* path,
                             char* errbuf, int errbuf_len);

char* toporoom_document_to_sceneir_json(TopoRoomDocument* doc);
void toporoom_string_free(char* s);

/* Load 方案 from SceneIR JSON text. Caller owns the document; NULL on error. */
TopoRoomDocument* toporoom_document_from_sceneir_json(const char* json, char* errbuf,
                                                      int errbuf_len);

/* Load 方案 from a SceneIR JSON file. Caller owns the document; NULL on error. */
TopoRoomDocument* toporoom_document_load(const char* path, char* errbuf, int errbuf_len);

/* Save 方案 as SceneIR JSON (creates parent directories). Returns 0 on success. */
int toporoom_document_save(TopoRoomDocument* doc, const char* path, char* errbuf,
                           int errbuf_len);

/*
 * Probe GeometryPort + StatusGate without writing files.
 * status_out receives "ok" or "fault". Returns 0 if a structural .glb would be
 * allowed, 2 on geometry fault, 1 on bad arguments. DXF/PDF may still export
 * when this returns 2 (semantic 户型图).
 */
int toporoom_document_rebuild_status(TopoRoomDocument* doc, char* status_out, int status_len,
                                     char* errbuf, int errbuf_len);

/*
 * Debug / emulator: four walls, two laser key edges, one door, close room,
 * export glb+dxf+pdf into out_dir (created if needed). Document must be empty.
 * If guide is non-NULL, its FSM is advanced to export-ready on success.
 */
int toporoom_debug_fake_one_room(TopoRoomDocument* doc, TopoRoomGuide* guide,
                                 const char* out_dir, char* errbuf, int errbuf_len);

/* --- GuidedRoomSession (量房会话 / CaptureSession) --- */

TopoRoomGuide* toporoom_guide_create(void);
void toporoom_guide_destroy(TopoRoomGuide* guide);
void toporoom_guide_mark_host_ok(TopoRoomGuide* guide, int ok);
void toporoom_guide_note_wall(TopoRoomGuide* guide);
void toporoom_guide_note_opening(TopoRoomGuide* guide);
void toporoom_guide_note_key_measurement(TopoRoomGuide* guide, const char* source,
                                         int typed_explicit);
void toporoom_guide_note_rebuild(TopoRoomGuide* guide, int ok);
const char* toporoom_guide_phase(const TopoRoomGuide* guide);
int toporoom_guide_can_export(const TopoRoomGuide* guide);
const char* toporoom_guide_blocking_reason(const TopoRoomGuide* guide);

/* Observe 方案 walls/openings/key measurements; rebuild_ok is 0/1. */
int toporoom_guide_sync_from_document(TopoRoomGuide* guide, TopoRoomDocument* doc,
                                      int rebuild_ok);

/*
 * Real one-room edit path (not debug_fake_one_room): 4 walls, 2 laser keys,
 * archway opening, close room, sync guide. Does not export.
 */
int toporoom_document_run_guided_edit(TopoRoomDocument* doc, TopoRoomGuide* guide,
                                      char* errbuf, int errbuf_len);

/* --- EvidencePack (sidecar; may be empty; never SceneIR) --- */

TopoRoomEvidence* toporoom_evidence_create(const char* document_id);
void toporoom_evidence_destroy(TopoRoomEvidence* pack);
int toporoom_evidence_empty(const TopoRoomEvidence* pack);
int toporoom_evidence_attach(TopoRoomEvidence* pack, const char* id, const char* kind,
                             const char* uri);
int toporoom_evidence_detach(TopoRoomEvidence* pack, const char* id);
void toporoom_evidence_detach_all(TopoRoomEvidence* pack);

/* --- Whitelist / ReleaseTrain --- */

int toporoom_whitelist_allows(const char* json_text, const char* phone_model,
                              int android_api, const char* module_sku,
                              const char* firmware, const char* hub_sku,
                              const char* app_version);

/* Always 0 in P0. */
int toporoom_ios_external_depth_in_p0(void);

int toporoom_release_train_matches(const char* json_text, const char* software_tag,
                                   const char* module_sku, const char* firmware,
                                   int whitelist_version, const char* hub_firmware);

/* TopoRoom hub GATT packing (no BLE stack). out_len must be >= 4 / 12. Returns 0. */
int toporoom_hub_pack_measure_cmd(unsigned char* out, int out_len, unsigned timeout_ms);
int toporoom_hub_parse_length_notify_mm(const unsigned char* in, int len, double* out_mm);

#ifdef __cplusplus
}
#endif
