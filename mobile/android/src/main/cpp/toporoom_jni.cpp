#include "toporoom/c_api/toporoom.h"

#if defined(ANDROID) || defined(__ANDROID__)
#include <jni.h>

extern "C" JNIEXPORT jstring JNICALL
Java_com_toporoom_core_NativeCore_nativeVersion(JNIEnv* env, jclass /*clazz*/) {
  return env->NewStringUTF(toporoom_version());
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_toporoom_core_NativeCore_nativeCreateDocument(JNIEnv* env, jclass /*clazz*/,
                                                       jstring id) {
  const char* c_id = env->GetStringUTFChars(id, nullptr);
  TopoRoomDocument* doc = toporoom_document_create(c_id);
  env->ReleaseStringUTFChars(id, c_id);
  return reinterpret_cast<jlong>(doc);
}

extern "C" JNIEXPORT void JNICALL
Java_com_toporoom_core_NativeCore_nativeDestroyDocument(JNIEnv* /*env*/, jclass /*clazz*/,
                                                        jlong handle) {
  toporoom_document_destroy(reinterpret_cast<TopoRoomDocument*>(handle));
}

#endif  // ANDROID
