package com.toporoom.app

import com.toporoom.core.NativeCore

data class WhitelistQuery(
    val phoneModel: String,
    val androidApi: Int,
    val moduleSku: String = "orbbec_gemini_e",
    val firmware: String = "1.2.0",
    val hubSku: String = "none",
    val appVersion: String = "0.1.0",
)

data class LoadResult(val handle: Long, val error: String)

/**
 * JNI / Fake façade over `toporoom.h`. Empty string means success on mutating calls.
 */
interface TopoRoomBridge {
    fun version(): String
    fun createDocument(id: String): Long
    fun destroyDocument(handle: Long)
    fun firstStoreyId(handle: Long): String
    fun addWall(
        handle: Long,
        storeyId: String,
        wallId: String,
        x0: Double,
        y0: Double,
        x1: Double,
        y1: Double,
        thicknessMm: Double,
        heightMm: Double,
    ): String
    fun addOpening(
        handle: Long,
        storeyId: String,
        wallId: String,
        openingId: String,
        kind: String,
        widthMm: Double,
        heightMm: Double,
        offsetMm: Double,
        sillMm: Double,
    ): String
    fun moveWall(
        handle: Long,
        storeyId: String,
        wallId: String,
        x0: Double,
        y0: Double,
        x1: Double,
        y1: Double,
    ): String = ""
    fun resizeWall(handle: Long, storeyId: String, wallId: String, lengthMm: Double): String = ""
    fun deleteWall(handle: Long, storeyId: String, wallId: String): String = ""
    fun setWallHeight(handle: Long, storeyId: String, wallId: String, heightMm: Double): String = ""
    fun updateOpening(
        handle: Long,
        storeyId: String,
        openingId: String,
        kind: String,
        widthMm: Double,
        heightMm: Double,
        offsetMm: Double,
        sillMm: Double,
    ): String = ""
    fun deleteOpening(handle: Long, storeyId: String, openingId: String): String = ""
    fun setRoomAttributes(
        handle: Long,
        storeyId: String,
        roomId: String,
        name: String,
        spaceType: String,
        hasClearHeight: Boolean,
        clearHeightMm: Double,
    ): String = ""
    fun setStoreyHeight(
        handle: Long,
        storeyId: String,
        heightMm: Double,
        followMatchingWalls: Boolean,
    ): String = ""
    fun placeHosted(
        handle: Long,
        storeyId: String,
        componentId: String,
        kind: String,
        zBottomMm: Double,
        depthMm: Double,
        hostWallId: String?,
    ): String = ""
    fun updateHosted(
        handle: Long,
        storeyId: String,
        componentId: String,
        kind: String,
        zBottomMm: Double,
        depthMm: Double,
        hostWallId: String?,
    ): String = ""
    fun deleteHosted(handle: Long, storeyId: String, componentId: String): String = ""
    fun setMeasurement(
        handle: Long,
        measurementId: String,
        valueMm: Double,
        source: String,
        instrumentId: String?,
        betweenCsv: String?,
    ): String
    fun closeRoom(handle: Long, storeyId: String, roomId: String, wallIdsCsv: String): String
    fun export(handle: Long, format: String, path: String): String
    fun sceneIrJson(handle: Long): String = "{}"
    fun loadFromJson(json: String): LoadResult = LoadResult(0, "not implemented")
    fun loadFromFile(path: String): LoadResult = LoadResult(0, "not implemented")
    fun saveToFile(handle: Long, path: String): String = ""
    fun debugFakeOneRoom(doc: Long, guide: Long, outDir: String): String
    fun runGuidedEdit(doc: Long, guide: Long): String = ""
    fun guideCreate(): Long
    fun guideDestroy(handle: Long)
    fun guideMarkHostOk(handle: Long, ok: Boolean)
    fun guideNoteWall(handle: Long)
    fun guideNoteOpening(handle: Long)
    fun guideNoteKey(handle: Long, source: String, typedExplicit: Boolean)
    fun guideNoteRebuild(handle: Long, ok: Boolean)
    fun guideSyncFromDocument(guide: Long, doc: Long, rebuildOk: Boolean): Int = 0
    fun guidePhase(handle: Long): String
    fun guideCanExport(handle: Long): Boolean
    fun guideBlockingReason(handle: Long): String
    fun evidenceCreate(documentId: String): Long
    fun evidenceDestroy(handle: Long)
    fun evidenceEmpty(handle: Long): Boolean
    fun evidenceAttach(handle: Long, id: String, kind: String, uri: String): Int
    fun whitelistAllows(json: String, query: WhitelistQuery): Boolean
    fun releaseTrainMatches(
        json: String,
        softwareTag: String,
        moduleSku: String,
        firmware: String,
        whitelistVersion: Int,
    ): Boolean
}

class JniTopoRoomBridge : TopoRoomBridge {
    override fun version() = NativeCore.nativeVersion()
    override fun createDocument(id: String) = NativeCore.nativeCreateDocument(id)
    override fun destroyDocument(handle: Long) = NativeCore.nativeDestroyDocument(handle)
    override fun firstStoreyId(handle: Long) = NativeCore.nativeFirstStoreyId(handle)
    override fun addWall(
        handle: Long,
        storeyId: String,
        wallId: String,
        x0: Double,
        y0: Double,
        x1: Double,
        y1: Double,
        thicknessMm: Double,
        heightMm: Double,
    ) = NativeCore.nativeAddWall(handle, storeyId, wallId, x0, y0, x1, y1, thicknessMm, heightMm)
    override fun addOpening(
        handle: Long,
        storeyId: String,
        wallId: String,
        openingId: String,
        kind: String,
        widthMm: Double,
        heightMm: Double,
        offsetMm: Double,
        sillMm: Double,
    ) = NativeCore.nativeAddOpening(
        handle, storeyId, wallId, openingId, kind, widthMm, heightMm, offsetMm, sillMm,
    )
    override fun moveWall(
        handle: Long,
        storeyId: String,
        wallId: String,
        x0: Double,
        y0: Double,
        x1: Double,
        y1: Double,
    ) = NativeCore.nativeMoveWall(handle, storeyId, wallId, x0, y0, x1, y1)
    override fun resizeWall(handle: Long, storeyId: String, wallId: String, lengthMm: Double) =
        NativeCore.nativeResizeWall(handle, storeyId, wallId, lengthMm)
    override fun deleteWall(handle: Long, storeyId: String, wallId: String) =
        NativeCore.nativeDeleteWall(handle, storeyId, wallId)
    override fun setWallHeight(handle: Long, storeyId: String, wallId: String, heightMm: Double) =
        NativeCore.nativeSetWallHeight(handle, storeyId, wallId, heightMm)
    override fun updateOpening(
        handle: Long,
        storeyId: String,
        openingId: String,
        kind: String,
        widthMm: Double,
        heightMm: Double,
        offsetMm: Double,
        sillMm: Double,
    ) = NativeCore.nativeUpdateOpening(
        handle, storeyId, openingId, kind, widthMm, heightMm, offsetMm, sillMm,
    )
    override fun deleteOpening(handle: Long, storeyId: String, openingId: String) =
        NativeCore.nativeDeleteOpening(handle, storeyId, openingId)
    override fun setRoomAttributes(
        handle: Long,
        storeyId: String,
        roomId: String,
        name: String,
        spaceType: String,
        hasClearHeight: Boolean,
        clearHeightMm: Double,
    ) = NativeCore.nativeSetRoomAttributes(
        handle, storeyId, roomId, name, spaceType, hasClearHeight, clearHeightMm,
    )
    override fun setStoreyHeight(
        handle: Long,
        storeyId: String,
        heightMm: Double,
        followMatchingWalls: Boolean,
    ) = NativeCore.nativeSetStoreyHeight(handle, storeyId, heightMm, followMatchingWalls)
    override fun placeHosted(
        handle: Long,
        storeyId: String,
        componentId: String,
        kind: String,
        zBottomMm: Double,
        depthMm: Double,
        hostWallId: String?,
    ) = NativeCore.nativePlaceHosted(
        handle, storeyId, componentId, kind, zBottomMm, depthMm, hostWallId,
    )
    override fun updateHosted(
        handle: Long,
        storeyId: String,
        componentId: String,
        kind: String,
        zBottomMm: Double,
        depthMm: Double,
        hostWallId: String?,
    ) = NativeCore.nativeUpdateHosted(
        handle, storeyId, componentId, kind, zBottomMm, depthMm, hostWallId,
    )
    override fun deleteHosted(handle: Long, storeyId: String, componentId: String) =
        NativeCore.nativeDeleteHosted(handle, storeyId, componentId)
    override fun setMeasurement(
        handle: Long,
        measurementId: String,
        valueMm: Double,
        source: String,
        instrumentId: String?,
        betweenCsv: String?,
    ) = NativeCore.nativeSetMeasurement(
        handle, measurementId, valueMm, source, instrumentId, betweenCsv, null, null, null,
    )
    override fun closeRoom(handle: Long, storeyId: String, roomId: String, wallIdsCsv: String) =
        NativeCore.nativeCloseRoom(handle, storeyId, roomId, wallIdsCsv)
    override fun export(handle: Long, format: String, path: String) =
        NativeCore.nativeExport(handle, format, path)
    override fun sceneIrJson(handle: Long) = NativeCore.nativeSceneIrJson(handle) ?: "{}"
    override fun loadFromJson(json: String): LoadResult {
        val out = LongArray(1)
        val err = NativeCore.nativeLoadFromJson(json, out)
        return LoadResult(if (err.isNullOrEmpty()) out[0] else 0, err ?: "")
    }
    override fun loadFromFile(path: String): LoadResult {
        val out = LongArray(1)
        val err = NativeCore.nativeLoadFromFile(path, out)
        return LoadResult(if (err.isNullOrEmpty()) out[0] else 0, err ?: "")
    }
    override fun saveToFile(handle: Long, path: String) = NativeCore.nativeSaveToFile(handle, path)
    override fun debugFakeOneRoom(doc: Long, guide: Long, outDir: String) =
        NativeCore.nativeDebugFakeOneRoom(doc, guide, outDir)
    override fun runGuidedEdit(doc: Long, guide: Long) =
        NativeCore.nativeRunGuidedEdit(doc, guide)
    override fun guideCreate() = NativeCore.nativeGuideCreate()
    override fun guideDestroy(handle: Long) = NativeCore.nativeGuideDestroy(handle)
    override fun guideMarkHostOk(handle: Long, ok: Boolean) =
        NativeCore.nativeGuideMarkHostOk(handle, ok)
    override fun guideNoteWall(handle: Long) = NativeCore.nativeGuideNoteWall(handle)
    override fun guideNoteOpening(handle: Long) = NativeCore.nativeGuideNoteOpening(handle)
    override fun guideNoteKey(handle: Long, source: String, typedExplicit: Boolean) =
        NativeCore.nativeGuideNoteKey(handle, source, typedExplicit)
    override fun guideNoteRebuild(handle: Long, ok: Boolean) =
        NativeCore.nativeGuideNoteRebuild(handle, ok)
    override fun guideSyncFromDocument(guide: Long, doc: Long, rebuildOk: Boolean) =
        NativeCore.nativeGuideSyncFromDocument(guide, doc, rebuildOk)
    override fun guidePhase(handle: Long) = NativeCore.nativeGuidePhase(handle)
    override fun guideCanExport(handle: Long) = NativeCore.nativeGuideCanExport(handle)
    override fun guideBlockingReason(handle: Long) = NativeCore.nativeGuideBlockingReason(handle)
    override fun evidenceCreate(documentId: String) = NativeCore.nativeEvidenceCreate(documentId)
    override fun evidenceDestroy(handle: Long) = NativeCore.nativeEvidenceDestroy(handle)
    override fun evidenceEmpty(handle: Long) = NativeCore.nativeEvidenceEmpty(handle)
    override fun evidenceAttach(handle: Long, id: String, kind: String, uri: String) =
        NativeCore.nativeEvidenceAttach(handle, id, kind, uri)
    override fun whitelistAllows(json: String, query: WhitelistQuery) =
        NativeCore.nativeWhitelistAllows(
            json, query.phoneModel, query.androidApi, query.moduleSku, query.firmware,
            query.hubSku, query.appVersion,
        )
    override fun releaseTrainMatches(
        json: String,
        softwareTag: String,
        moduleSku: String,
        firmware: String,
        whitelistVersion: Int,
    ) = NativeCore.nativeReleaseTrainMatches(
        json, softwareTag, moduleSku, firmware, whitelistVersion,
    )
}
