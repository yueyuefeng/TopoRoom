package com.toporoom.core;

/**
 * JNI façade over the shared C++ core. Real capture/export UI lives in a later
 * Android app module; this class only proves the load/link path.
 */
public final class NativeCore {
  static {
    System.loadLibrary("toporoom_jni");
  }

  private NativeCore() {}

  public static native String nativeVersion();

  public static native long nativeCreateDocument(String id);

  public static native void nativeDestroyDocument(long handle);
}
