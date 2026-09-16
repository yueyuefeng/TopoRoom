package com.toporoom.core;

/**
 * JNI façade over the shared C++ core ({@code toporoom.h}).
 * Mutating methods return an empty string on success, otherwise an error.
 */
public final class NativeCore {
  static {
    System.loadLibrary("toporoom_jni");
  }

  private NativeCore() {}

  public static native String nativeVersion();

  public static native long nativeCreateDocument(String id);

  public static native void nativeDestroyDocument(long handle);

  public static native String nativeFirstStoreyId(long handle);

  public static native String nativeAddWall(long handle, String storeyId, String wallId,
      double x0, double y0, double x1, double y1, double thicknessMm, double heightMm);

  public static native String nativeAddOpening(long handle, String storeyId, String wallId,
      String openingId, String kind, double widthMm, double heightMm, double offsetMm,
      double sillMm);

  public static native String nativeSetMeasurement(long handle, String measurementId,
      double valueMm, String source, String instrumentId, String betweenCsv,
      String targetType, String targetId, String targetField);

  public static native String nativeCloseRoom(long handle, String storeyId, String roomId,
      String wallIdsCsv);

  public static native String nativeExport(long handle, String format, String path);

  public static native String nativeSceneIrJson(long handle);

  public static native String nativeDebugFakeOneRoom(long doc, long guide, String outDir);

  public static native long nativeGuideCreate();

  public static native void nativeGuideDestroy(long handle);

  public static native void nativeGuideMarkHostOk(long handle, boolean ok);

  public static native void nativeGuideNoteWall(long handle);

  public static native void nativeGuideNoteOpening(long handle);

  public static native void nativeGuideNoteKey(long handle, String source,
      boolean typedExplicit);

  public static native void nativeGuideNoteRebuild(long handle, boolean ok);

  public static native String nativeGuidePhase(long handle);

  public static native boolean nativeGuideCanExport(long handle);

  public static native String nativeGuideBlockingReason(long handle);

  public static native long nativeEvidenceCreate(String documentId);

  public static native void nativeEvidenceDestroy(long handle);

  public static native boolean nativeEvidenceEmpty(long handle);

  public static native int nativeEvidenceAttach(long handle, String id, String kind,
      String uri);

  public static native boolean nativeWhitelistAllows(String json, String phoneModel,
      int androidApi, String moduleSku, String firmware, String hubSku, String appVersion);

  public static native boolean nativeIosExternalDepthInP0();

  public static native boolean nativeReleaseTrainMatches(String json, String softwareTag,
      String moduleSku, String firmware, int whitelistVersion);
}
