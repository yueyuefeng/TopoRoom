#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct TopoRoomDocument TopoRoomDocument;

const char* toporoom_version(void);

TopoRoomDocument* toporoom_document_create(const char* id);
void toporoom_document_destroy(TopoRoomDocument* doc);

/* Returns 0 on success. Error message (if any) is written to errbuf. */
int toporoom_document_add_wall(TopoRoomDocument* doc, const char* storey_id,
                               const char* wall_id, double x0, double y0, double x1,
                               double y1, double thickness_mm, double height_mm,
                               char* errbuf, int errbuf_len);

char* toporoom_document_to_sceneir_json(TopoRoomDocument* doc);
void toporoom_string_free(char* s);

#ifdef __cplusplus
}
#endif
