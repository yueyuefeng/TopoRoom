#include "toporoom/c_api/toporoom.h"

#if defined(ANDROID) || defined(__ANDROID__)
#include <jni.h>

namespace {

struct JUtf {
  JNIEnv* env;
  jstring js;
  const char* c;
  JUtf(JNIEnv* e, jstring s)
      : env(e), js(s), c(s ? e->GetStringUTFChars(s, nullptr) : nullptr) {}
  ~JUtf() {
    if (js && c) env->ReleaseStringUTFChars(js, c);
  }
  JUtf(const JUtf&) = delete;
  JUtf& operator=(const JUtf&) = delete;
};

jstring jerr(JNIEnv* env, int rc, const char* err) {
  if (rc == 0) return env->NewStringUTF("");
  return env->NewStringUTF(err && err[0] ? err : "error");
}

}  // namespace

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeVersion(JNIEnv* env, jclass /*clazz*/) {
  return env->NewStringUTF(toporoom_version());
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_toporoom_core_NativeCore_nativeCreateDocument(JNIEnv* env, jclass /*clazz*/,
                                                       jstring id) {
  JUtf c_id(env, id);
  return reinterpret_cast<jlong>(toporoom_document_create(c_id.c));
}

extern "C" JNIEXPORT void JNICALL
Java_com_toporoom_core_NativeCore_nativeDestroyDocument(JNIEnv* /*env*/, jclass /*clazz*/,
                                                        jlong handle) {
  toporoom_document_destroy(reinterpret_cast<TopoRoomDocument*>(handle));
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeFirstStoreyId(JNIEnv* env, jclass /*clazz*/,
                                                      jlong handle) {
  char buf[128] = {};
  if (toporoom_document_first_storey_id(reinterpret_cast<TopoRoomDocument*>(handle), buf,
                                        sizeof(buf)) != 0) {
    return env->NewStringUTF("storey_1");
  }
  return env->NewStringUTF(buf);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeAddWall(JNIEnv* env, jclass /*clazz*/, jlong handle,
                                                jstring storeyId, jstring wallId, jdouble x0,
                                                jdouble y0, jdouble x1, jdouble y1,
                                                jdouble thicknessMm, jdouble heightMm) {
  JUtf storey(env, storeyId);
  JUtf wall(env, wallId);
  char err[256] = {};
  const int rc = toporoom_document_add_wall(reinterpret_cast<TopoRoomDocument*>(handle),
                                            storey.c, wall.c, x0, y0, x1, y1, thicknessMm,
                                            heightMm, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeAddOpening(
    JNIEnv* env, jclass /*clazz*/, jlong handle, jstring storeyId, jstring wallId,
    jstring openingId, jstring kind, jdouble widthMm, jdouble heightMm, jdouble offsetMm,
    jdouble sillMm) {
  JUtf storey(env, storeyId);
  JUtf wall(env, wallId);
  JUtf opening(env, openingId);
  JUtf k(env, kind);
  char err[256] = {};
  const int rc = toporoom_document_add_opening(
      reinterpret_cast<TopoRoomDocument*>(handle), storey.c, wall.c, opening.c, k.c,
      widthMm, heightMm, offsetMm, sillMm, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeSetMeasurement(
    JNIEnv* env, jclass /*clazz*/, jlong handle, jstring measurementId, jdouble valueMm,
    jstring source, jstring instrumentId, jstring betweenCsv, jstring targetType,
    jstring targetId, jstring targetField) {
  JUtf mid(env, measurementId);
  JUtf src(env, source);
  JUtf inst(env, instrumentId);
  JUtf between(env, betweenCsv);
  JUtf ttype(env, targetType);
  JUtf tid(env, targetId);
  JUtf tfield(env, targetField);
  char err[256] = {};
  const int rc = toporoom_document_set_measurement(
      reinterpret_cast<TopoRoomDocument*>(handle), mid.c, valueMm, src.c, inst.c,
      between.c, ttype.c, tid.c, tfield.c, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeCloseRoom(JNIEnv* env, jclass /*clazz*/,
                                                  jlong handle, jstring storeyId,
                                                  jstring roomId, jstring wallIdsCsv) {
  JUtf storey(env, storeyId);
  JUtf room(env, roomId);
  JUtf walls(env, wallIdsCsv);
  char err[256] = {};
  const int rc =
      toporoom_document_close_room(reinterpret_cast<TopoRoomDocument*>(handle), storey.c,
                                   room.c, walls.c, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeExport(JNIEnv* env, jclass /*clazz*/, jlong handle,
                                               jstring format, jstring path) {
  JUtf fmt(env, format);
  JUtf p(env, path);
  char err[256] = {};
  const int rc = toporoom_document_export(reinterpret_cast<TopoRoomDocument*>(handle),
                                          fmt.c, p.c, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeSceneIrJson(JNIEnv* env, jclass /*clazz*/,
                                                    jlong handle) {
  char* json =
      toporoom_document_to_sceneir_json(reinterpret_cast<TopoRoomDocument*>(handle));
  if (!json) return nullptr;
  jstring out = env->NewStringUTF(json);
  toporoom_string_free(json);
  return out;
}

namespace {

jstring load_into(JNIEnv* env, TopoRoomDocument* doc, const char* err, jlongArray outHandle) {
  if (!doc) return env->NewStringUTF(err && err[0] ? err : "load failed");
  if (!outHandle || env->GetArrayLength(outHandle) < 1) {
    toporoom_document_destroy(doc);
    return env->NewStringUTF("outHandle required");
  }
  const jlong handle = reinterpret_cast<jlong>(doc);
  env->SetLongArrayRegion(outHandle, 0, 1, &handle);
  return env->NewStringUTF("");
}

}  // namespace

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeLoadFromJson(JNIEnv* env, jclass /*clazz*/,
                                                     jstring json, jlongArray outHandle) {
  JUtf j(env, json);
  char err[512] = {};
  TopoRoomDocument* doc = toporoom_document_from_sceneir_json(j.c, err, sizeof(err));
  return load_into(env, doc, err, outHandle);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeLoadFromFile(JNIEnv* env, jclass /*clazz*/,
                                                     jstring path, jlongArray outHandle) {
  JUtf p(env, path);
  char err[512] = {};
  TopoRoomDocument* doc = toporoom_document_load(p.c, err, sizeof(err));
  return load_into(env, doc, err, outHandle);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeSaveToFile(JNIEnv* env, jclass /*clazz*/,
                                                   jlong handle, jstring path) {
  JUtf p(env, path);
  char err[256] = {};
  const int rc = toporoom_document_save(reinterpret_cast<TopoRoomDocument*>(handle), p.c,
                                        err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeMoveWall(JNIEnv* env, jclass /*clazz*/,
                                                 jlong handle, jstring storeyId,
                                                 jstring wallId, jdouble x0, jdouble y0,
                                                 jdouble x1, jdouble y1) {
  JUtf storey(env, storeyId);
  JUtf wall(env, wallId);
  char err[256] = {};
  const int rc = toporoom_document_move_wall(reinterpret_cast<TopoRoomDocument*>(handle),
                                             storey.c, wall.c, x0, y0, x1, y1, err,
                                             sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeResizeWall(JNIEnv* env, jclass /*clazz*/,
                                                   jlong handle, jstring storeyId,
                                                   jstring wallId, jdouble lengthMm) {
  JUtf storey(env, storeyId);
  JUtf wall(env, wallId);
  char err[256] = {};
  const int rc = toporoom_document_resize_wall(reinterpret_cast<TopoRoomDocument*>(handle),
                                               storey.c, wall.c, lengthMm, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeDeleteWall(JNIEnv* env, jclass /*clazz*/,
                                                   jlong handle, jstring storeyId,
                                                   jstring wallId) {
  JUtf storey(env, storeyId);
  JUtf wall(env, wallId);
  char err[256] = {};
  const int rc = toporoom_document_delete_wall(reinterpret_cast<TopoRoomDocument*>(handle),
                                               storey.c, wall.c, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeSetWallHeight(JNIEnv* env, jclass /*clazz*/,
                                                      jlong handle, jstring storeyId,
                                                      jstring wallId, jdouble heightMm) {
  JUtf storey(env, storeyId);
  JUtf wall(env, wallId);
  char err[256] = {};
  const int rc =
      toporoom_document_set_wall_height(reinterpret_cast<TopoRoomDocument*>(handle),
                                        storey.c, wall.c, heightMm, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeUpdateOpening(
    JNIEnv* env, jclass /*clazz*/, jlong handle, jstring storeyId, jstring openingId,
    jstring kind, jdouble widthMm, jdouble heightMm, jdouble offsetMm, jdouble sillMm) {
  JUtf storey(env, storeyId);
  JUtf opening(env, openingId);
  JUtf k(env, kind);
  char err[256] = {};
  const int rc = toporoom_document_update_opening(
      reinterpret_cast<TopoRoomDocument*>(handle), storey.c, opening.c, k.c, widthMm,
      heightMm, offsetMm, sillMm, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeDeleteOpening(JNIEnv* env, jclass /*clazz*/,
                                                      jlong handle, jstring storeyId,
                                                      jstring openingId) {
  JUtf storey(env, storeyId);
  JUtf opening(env, openingId);
  char err[256] = {};
  const int rc = toporoom_document_delete_opening(
      reinterpret_cast<TopoRoomDocument*>(handle), storey.c, opening.c, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeSetRoomAttributes(
    JNIEnv* env, jclass /*clazz*/, jlong handle, jstring storeyId, jstring roomId,
    jstring name, jstring spaceType, jboolean hasClearHeight, jdouble clearHeightMm) {
  JUtf storey(env, storeyId);
  JUtf room(env, roomId);
  JUtf n(env, name);
  JUtf space(env, spaceType);
  char err[256] = {};
  const int rc = toporoom_document_set_room_attributes(
      reinterpret_cast<TopoRoomDocument*>(handle), storey.c, room.c, n.c, space.c,
      hasClearHeight ? 1 : 0, clearHeightMm, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeSetStoreyHeight(JNIEnv* env, jclass /*clazz*/,
                                                        jlong handle, jstring storeyId,
                                                        jdouble heightMm,
                                                        jboolean followMatchingWalls) {
  JUtf storey(env, storeyId);
  char err[256] = {};
  const int rc = toporoom_document_set_storey_height(
      reinterpret_cast<TopoRoomDocument*>(handle), storey.c, heightMm,
      followMatchingWalls ? 1 : 0, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativePlaceHosted(
    JNIEnv* env, jclass /*clazz*/, jlong handle, jstring storeyId, jstring componentId,
    jstring kind, jdouble zBottomMm, jdouble depthMm, jstring hostWallId) {
  JUtf storey(env, storeyId);
  JUtf id(env, componentId);
  JUtf k(env, kind);
  JUtf host(env, hostWallId);
  char err[256] = {};
  const int rc = toporoom_document_place_hosted(
      reinterpret_cast<TopoRoomDocument*>(handle), storey.c, id.c, k.c, zBottomMm,
      depthMm, host.c, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeUpdateHosted(
    JNIEnv* env, jclass /*clazz*/, jlong handle, jstring storeyId, jstring componentId,
    jstring kind, jdouble zBottomMm, jdouble depthMm, jstring hostWallId) {
  JUtf storey(env, storeyId);
  JUtf id(env, componentId);
  JUtf k(env, kind);
  JUtf host(env, hostWallId);
  char err[256] = {};
  const int rc = toporoom_document_update_hosted(
      reinterpret_cast<TopoRoomDocument*>(handle), storey.c, id.c, k.c, zBottomMm,
      depthMm, host.c, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeDeleteHosted(JNIEnv* env, jclass /*clazz*/,
                                                     jlong handle, jstring storeyId,
                                                     jstring componentId) {
  JUtf storey(env, storeyId);
  JUtf id(env, componentId);
  char err[256] = {};
  const int rc = toporoom_document_delete_hosted(
      reinterpret_cast<TopoRoomDocument*>(handle), storey.c, id.c, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jint JNICALL
Java_com_toporoom_core_NativeCore_nativeGuideSyncFromDocument(JNIEnv* /*env*/,
                                                              jclass /*clazz*/,
                                                              jlong guide, jlong doc,
                                                              jboolean rebuildOk) {
  return toporoom_guide_sync_from_document(reinterpret_cast<TopoRoomGuide*>(guide),
                                           reinterpret_cast<TopoRoomDocument*>(doc),
                                           rebuildOk ? 1 : 0);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeRunGuidedEdit(JNIEnv* env, jclass /*clazz*/,
                                                      jlong doc, jlong guide) {
  char err[256] = {};
  const int rc = toporoom_document_run_guided_edit(
      reinterpret_cast<TopoRoomDocument*>(doc), reinterpret_cast<TopoRoomGuide*>(guide),
      err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeDebugFakeOneRoom(JNIEnv* env, jclass /*clazz*/,
                                                         jlong doc, jlong guide,
                                                         jstring outDir) {
  JUtf dir(env, outDir);
  char err[256] = {};
  const int rc = toporoom_debug_fake_one_room(reinterpret_cast<TopoRoomDocument*>(doc),
                                              reinterpret_cast<TopoRoomGuide*>(guide),
                                              dir.c, err, sizeof(err));
  return jerr(env, rc, err);
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_toporoom_core_NativeCore_nativeGuideCreate(JNIEnv* /*env*/, jclass /*clazz*/) {
  return reinterpret_cast<jlong>(toporoom_guide_create());
}

extern "C" JNIEXPORT void JNICALL
Java_com_toporoom_core_NativeCore_nativeGuideDestroy(JNIEnv* /*env*/, jclass /*clazz*/,
                                                     jlong handle) {
  toporoom_guide_destroy(reinterpret_cast<TopoRoomGuide*>(handle));
}

extern "C" JNIEXPORT void JNICALL
Java_com_toporoom_core_NativeCore_nativeGuideMarkHostOk(JNIEnv* /*env*/, jclass /*clazz*/,
                                                        jlong handle, jboolean ok) {
  toporoom_guide_mark_host_ok(reinterpret_cast<TopoRoomGuide*>(handle), ok ? 1 : 0);
}

extern "C" JNIEXPORT void JNICALL
Java_com_toporoom_core_NativeCore_nativeGuideNoteWall(JNIEnv* /*env*/, jclass /*clazz*/,
                                                      jlong handle) {
  toporoom_guide_note_wall(reinterpret_cast<TopoRoomGuide*>(handle));
}

extern "C" JNIEXPORT void JNICALL
Java_com_toporoom_core_NativeCore_nativeGuideNoteOpening(JNIEnv* /*env*/, jclass /*clazz*/,
                                                         jlong handle) {
  toporoom_guide_note_opening(reinterpret_cast<TopoRoomGuide*>(handle));
}

extern "C" JNIEXPORT void JNICALL
Java_com_toporoom_core_NativeCore_nativeGuideNoteKey(JNIEnv* env, jclass /*clazz*/,
                                                     jlong handle, jstring source,
                                                     jboolean typedExplicit) {
  JUtf src(env, source);
  toporoom_guide_note_key_measurement(reinterpret_cast<TopoRoomGuide*>(handle), src.c,
                                      typedExplicit ? 1 : 0);
}

extern "C" JNIEXPORT void JNICALL
Java_com_toporoom_core_NativeCore_nativeGuideNoteRebuild(JNIEnv* /*env*/, jclass /*clazz*/,
                                                         jlong handle, jboolean ok) {
  toporoom_guide_note_rebuild(reinterpret_cast<TopoRoomGuide*>(handle), ok ? 1 : 0);
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeGuidePhase(JNIEnv* env, jclass /*clazz*/,
                                                   jlong handle) {
  return env->NewStringUTF(toporoom_guide_phase(reinterpret_cast<TopoRoomGuide*>(handle)));
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_toporoom_core_NativeCore_nativeGuideCanExport(JNIEnv* /*env*/, jclass /*clazz*/,
                                                       jlong handle) {
  return toporoom_guide_can_export(reinterpret_cast<TopoRoomGuide*>(handle)) ? JNI_TRUE
                                                                            : JNI_FALSE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeGuideBlockingReason(JNIEnv* env, jclass /*clazz*/,
                                                            jlong handle) {
  return env->NewStringUTF(
      toporoom_guide_blocking_reason(reinterpret_cast<TopoRoomGuide*>(handle)));
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_toporoom_core_NativeCore_nativeEvidenceCreate(JNIEnv* env, jclass /*clazz*/,
                                                       jstring documentId) {
  JUtf id(env, documentId);
  return reinterpret_cast<jlong>(toporoom_evidence_create(id.c));
}

extern "C" JNIEXPORT void JNICALL
Java_com_toporoom_core_NativeCore_nativeEvidenceDestroy(JNIEnv* /*env*/, jclass /*clazz*/,
                                                        jlong handle) {
  toporoom_evidence_destroy(reinterpret_cast<TopoRoomEvidence*>(handle));
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_toporoom_core_NativeCore_nativeEvidenceEmpty(JNIEnv* /*env*/, jclass /*clazz*/,
                                                      jlong handle) {
  return toporoom_evidence_empty(reinterpret_cast<TopoRoomEvidence*>(handle)) ? JNI_TRUE
                                                                             : JNI_FALSE;
}

extern "C" JNIEXPORT jint JNICALL
Java_com_toporoom_core_NativeCore_nativeEvidenceAttach(JNIEnv* env, jclass /*clazz*/,
                                                       jlong handle, jstring id,
                                                       jstring kind, jstring uri) {
  JUtf i(env, id);
  JUtf k(env, kind);
  JUtf u(env, uri);
  return toporoom_evidence_attach(reinterpret_cast<TopoRoomEvidence*>(handle), i.c, k.c,
                                  u.c);
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_toporoom_core_NativeCore_nativeWhitelistAllows(
    JNIEnv* env, jclass /*clazz*/, jstring json, jstring phoneModel, jint androidApi,
    jstring moduleSku, jstring firmware, jstring hubSku, jstring appVersion) {
  JUtf j(env, json);
  JUtf model(env, phoneModel);
  JUtf sku(env, moduleSku);
  JUtf fw(env, firmware);
  JUtf hub(env, hubSku);
  JUtf app(env, appVersion);
  return toporoom_whitelist_allows(j.c, model.c, androidApi, sku.c, fw.c, hub.c, app.c)
             ? JNI_TRUE
             : JNI_FALSE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_toporoom_core_NativeCore_nativeIosExternalDepthInP0(JNIEnv* /*env*/,
                                                             jclass /*clazz*/) {
  return toporoom_ios_external_depth_in_p0() ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_toporoom_core_NativeCore_nativeReleaseTrainMatches(
    JNIEnv* env, jclass /*clazz*/, jstring json, jstring softwareTag, jstring moduleSku,
    jstring firmware, jint whitelistVersion) {
  JUtf j(env, json);
  JUtf tag(env, softwareTag);
  JUtf sku(env, moduleSku);
  JUtf fw(env, firmware);
  return toporoom_release_train_matches(j.c, tag.c, sku.c, fw.c, whitelistVersion)
             ? JNI_TRUE
             : JNI_FALSE;
}

#endif  // ANDROID
