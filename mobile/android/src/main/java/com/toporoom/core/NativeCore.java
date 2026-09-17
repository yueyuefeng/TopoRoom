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

  public static native String nativeMoveWall(long handle, String storeyId, String wallId,
      double x0, double y0, double x1, double y1);

  public static native String nativeResizeWall(long handle, String storeyId, String wallId,
      double lengthMm);

  public static native String nativeDeleteWall(long handle, String storeyId, String wallId);

  public static native String nativeSetWallHeight(long handle, String storeyId, String wallId,
      double heightMm);

  public static native String nativeUpdateOpening(long handle, String storeyId,
      String openingId, String kind, double widthMm, double heightMm, double offsetMm,
      double sillMm);

  public static native String nativeDeleteOpening(long handle, String storeyId,
      String openingId);

  public static native String nativeSetRoomAttributes(long handle, String storeyId,
      String roomId, String name, String spaceType, boolean hasClearHeight,
      double clearHeightMm);

  public static native String nativeSetStoreyHeight(long handle, String storeyId,
      double heightMm, boolean followMatchingWalls);

  public static native String nativePlaceHosted(long handle, String storeyId,
      String componentId, String kind, double zBottomMm, double depthMm, String hostWallId);

  public static native String nativeUpdateHosted(long handle, String storeyId,
      String componentId, String kind, double zBottomMm, double depthMm, String hostWallId);

  public static native String nativeDeleteHosted(long handle, String storeyId,
      String componentId);

  public static native String nativeSetMeasurement(long handle, String measurementId,
      double valueMm, String source, String instrumentId, String betweenCsv,
      String targetType, String targetId, String targetField);

  public static native String nativeCloseRoom(long handle, String storeyId, String roomId,
      String wallIdsCsv);

  public static native String nativeExport(long handle, String format, String path);

  public static native String nativeSceneIrJson(long handle);

  /** Empty on success; writes the new document handle into {@code outHandle[0]}. */
  public static native String nativeLoadFromJson(String json, long[] outHandle);

  public static native String nativeLoadFromFile(String path, long[] outHandle);

  public static native String nativeSaveToFile(long handle, String path);

  public static native String nativeDebugFakeOneRoom(long doc, long guide, String outDir);

  public static native String nativeRunGuidedEdit(long doc, long guide);

  public static native long nativeGuideCreate();

  public static native void nativeGuideDestroy(long handle);

  public static native void nativeGuideMarkHostOk(long handle, boolean ok);

  public static native void nativeGuideNoteWall(long handle);

  public static native void nativeGuideNoteOpening(long handle);

  public static native void nativeGuideNoteKey(long handle, String source,
      boolean typedExplicit);

  public static native void nativeGuideNoteRebuild(long handle, boolean ok);

  public static native int nativeGuideSyncFromDocument(long guide, long doc,
      boolean rebuildOk);

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
      String moduleSku, String firmware, int whitelistVersion, String hubFirmware);

  public static native byte[] nativeHubPackMeasureCmd(int timeoutMs);

  public static native double nativeHubParseLengthNotifyMm(byte[] notify);
}
