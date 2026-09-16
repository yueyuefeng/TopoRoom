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

/* Copies the first storey id. Returns 0 on success. */
int toporoom_document_first_storey_id(TopoRoomDocument* doc, char* out, int out_len);

/* Returns 0 on success. Error message (if any) is written to errbuf. */
int toporoom_document_add_wall(TopoRoomDocument* doc, const char* storey_id,
                               const char* wall_id, double x0, double y0, double x1,
                               double y1, double thickness_mm, double height_mm,
                               char* errbuf, int errbuf_len);

/* kind: "door" | "window". */
int toporoom_document_add_opening(TopoRoomDocument* doc, const char* storey_id,
                                  const char* wall_id, const char* opening_id,
                                  const char* kind, double width_mm, double height_mm,
                                  double offset_mm, double sill_height_mm, char* errbuf,
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

/*
 * Debug / emulator: four walls, two laser key edges, one door, close room,
 * export glb+dxf+pdf into out_dir (created if needed). Document must be empty.
 * If guide is non-NULL, its FSM is advanced to export-ready on success.
 */
int toporoom_debug_fake_one_room(TopoRoomDocument* doc, TopoRoomGuide* guide,
                                 const char* out_dir, char* errbuf, int errbuf_len);

/* --- GuidedRoomSession --- */

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
                                   int whitelist_version);

#ifdef __cplusplus
}
#endif
