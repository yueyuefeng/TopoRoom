package com.toporoom.app

data class GuideUiState(
    val phase: String = "host_check",
    val canExport: Boolean = false,
    val blockingReason: String = "",
    val hostOk: Boolean = false,
    val usingFakeCapture: Boolean = false,
    val whitelistOk: Boolean = false,
    val log: String = "",
    val lastExportDir: String = "",
    val evidenceEmpty: Boolean = true,
)

data class WhitelistQuery(
    val phoneModel: String,
    val androidApi: Int,
    val moduleSku: String = "orbbec_gemini_e",
    val firmware: String = "3460",
    val hubSku: String = "none",
    val appVersion: String = "0.1.0",
)

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
    fun debugFakeOneRoom(doc: Long, guide: Long, outDir: String): String
    fun guideCreate(): Long
    fun guideDestroy(handle: Long)
    fun guideMarkHostOk(handle: Long, ok: Boolean)
    fun guideNoteWall(handle: Long)
    fun guideNoteOpening(handle: Long)
    fun guideNoteKey(handle: Long, source: String, typedExplicit: Boolean)
    fun guideNoteRebuild(handle: Long, ok: Boolean)
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
        hubFirmware: String,
    ): Boolean
}

class JniTopoRoomBridge : TopoRoomBridge {
    override fun version() = com.toporoom.core.NativeCore.nativeVersion()
    override fun createDocument(id: String) = com.toporoom.core.NativeCore.nativeCreateDocument(id)
    override fun destroyDocument(handle: Long) =
        com.toporoom.core.NativeCore.nativeDestroyDocument(handle)
    override fun firstStoreyId(handle: Long) =
        com.toporoom.core.NativeCore.nativeFirstStoreyId(handle)
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
    ) = com.toporoom.core.NativeCore.nativeAddWall(
        handle, storeyId, wallId, x0, y0, x1, y1, thicknessMm, heightMm,
    )
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
    ) = com.toporoom.core.NativeCore.nativeAddOpening(
        handle, storeyId, wallId, openingId, kind, widthMm, heightMm, offsetMm, sillMm,
    )
    override fun setMeasurement(
        handle: Long,
        measurementId: String,
        valueMm: Double,
        source: String,
        instrumentId: String?,
        betweenCsv: String?,
    ) = com.toporoom.core.NativeCore.nativeSetMeasurement(
        handle, measurementId, valueMm, source, instrumentId, betweenCsv, null, null, null,
    )
    override fun closeRoom(handle: Long, storeyId: String, roomId: String, wallIdsCsv: String) =
        com.toporoom.core.NativeCore.nativeCloseRoom(handle, storeyId, roomId, wallIdsCsv)
    override fun export(handle: Long, format: String, path: String) =
        com.toporoom.core.NativeCore.nativeExport(handle, format, path)
    override fun debugFakeOneRoom(doc: Long, guide: Long, outDir: String) =
        com.toporoom.core.NativeCore.nativeDebugFakeOneRoom(doc, guide, outDir)
    override fun guideCreate() = com.toporoom.core.NativeCore.nativeGuideCreate()
    override fun guideDestroy(handle: Long) =
        com.toporoom.core.NativeCore.nativeGuideDestroy(handle)
    override fun guideMarkHostOk(handle: Long, ok: Boolean) =
        com.toporoom.core.NativeCore.nativeGuideMarkHostOk(handle, ok)
    override fun guideNoteWall(handle: Long) =
        com.toporoom.core.NativeCore.nativeGuideNoteWall(handle)
    override fun guideNoteOpening(handle: Long) =
        com.toporoom.core.NativeCore.nativeGuideNoteOpening(handle)
    override fun guideNoteKey(handle: Long, source: String, typedExplicit: Boolean) =
        com.toporoom.core.NativeCore.nativeGuideNoteKey(handle, source, typedExplicit)
    override fun guideNoteRebuild(handle: Long, ok: Boolean) =
        com.toporoom.core.NativeCore.nativeGuideNoteRebuild(handle, ok)
    override fun guidePhase(handle: Long) = com.toporoom.core.NativeCore.nativeGuidePhase(handle)
    override fun guideCanExport(handle: Long) =
        com.toporoom.core.NativeCore.nativeGuideCanExport(handle)
    override fun guideBlockingReason(handle: Long) =
        com.toporoom.core.NativeCore.nativeGuideBlockingReason(handle)
    override fun evidenceCreate(documentId: String) =
        com.toporoom.core.NativeCore.nativeEvidenceCreate(documentId)
    override fun evidenceDestroy(handle: Long) =
        com.toporoom.core.NativeCore.nativeEvidenceDestroy(handle)
    override fun evidenceEmpty(handle: Long) =
        com.toporoom.core.NativeCore.nativeEvidenceEmpty(handle)
    override fun evidenceAttach(handle: Long, id: String, kind: String, uri: String) =
        com.toporoom.core.NativeCore.nativeEvidenceAttach(handle, id, kind, uri)
    override fun whitelistAllows(json: String, query: WhitelistQuery) =
        com.toporoom.core.NativeCore.nativeWhitelistAllows(
            json, query.phoneModel, query.androidApi, query.moduleSku, query.firmware,
            query.hubSku, query.appVersion,
        )
    override fun releaseTrainMatches(
        json: String,
        softwareTag: String,
        moduleSku: String,
        firmware: String,
        whitelistVersion: Int,
        hubFirmware: String,
    ) = com.toporoom.core.NativeCore.nativeReleaseTrainMatches(
        json, softwareTag, moduleSku, firmware, whitelistVersion, hubFirmware,
    )
}

class GuideViewModel(
    private val bridge: TopoRoomBridge,
    private val debugBuild: Boolean,
) {
    var state = GuideUiState()
        private set

    var documentId: String = "doc_android"
        private set
    var storeyId: String = "storey_1"
        private set

    internal var docHandle: Long = 0
    internal var guideHandle: Long = 0
    internal var evidenceHandle: Long = 0
    private var wallCount: Int = 0
    private var keyCount: Int = 0
    private val fakeLaserMm = ArrayDeque(listOf(4000.0, 3000.0))

    fun start(
        documentId: String,
        whitelistJson: String,
        query: WhitelistQuery,
        releaseTrainJson: String,
    ) {
        dispose()
        this.documentId = documentId
        docHandle = bridge.createDocument(documentId)
        guideHandle = bridge.guideCreate()
        evidenceHandle = bridge.evidenceCreate(documentId)
        storeyId = bridge.firstStoreyId(docHandle)
        val listed = bridge.whitelistAllows(whitelistJson, query)
        val trainOk = bridge.releaseTrainMatches(
            releaseTrainJson, "0.1.0", query.moduleSku, query.firmware, 1, "0.1.0",
        )
        val hostOk = listed || debugBuild
        bridge.guideMarkHostOk(guideHandle, hostOk)
        refresh(
            "whitelist=$listed debug=$debugBuild train=$trainOk version=${bridge.version()}",
            hostOk = hostOk,
            whitelistOk = listed,
            fake = debugBuild && !listed,
        )
    }

    fun addRectangleWalls(): String {
        val walls = listOf(
            Triple("wall_n", doubleArrayOf(0.0, 3000.0, 4000.0, 3000.0)),
            Triple("wall_e", doubleArrayOf(4000.0, 3000.0, 4000.0, 0.0)),
            Triple("wall_s", doubleArrayOf(4000.0, 0.0, 0.0, 0.0)),
            Triple("wall_w", doubleArrayOf(0.0, 0.0, 0.0, 3000.0)),
        )
        for ((id, xy) in walls) {
            val err = bridge.addWall(docHandle, storeyId, id, xy[0], xy[1], xy[2], xy[3], 200.0, 2800.0)
            if (err.isNotEmpty()) return err
            bridge.guideNoteWall(guideHandle)
            wallCount += 1
        }
        refresh("drew 4 walls")
        return ""
    }

    fun measureLaser(valueMm: Double, instrumentId: String, fake: Boolean): String {
        val id = "m_key_${keyCount + 1}"
        val err = bridge.setMeasurement(docHandle, id, valueMm, "laser", instrumentId, "wall_s")
        if (err.isNotEmpty()) return err
        bridge.guideNoteKey(guideHandle, "laser", false)
        keyCount += 1
        refresh(if (fake) "laser fake ${valueMm}mm" else "laser hub ${valueMm}mm id=$instrumentId")
        return ""
    }

    fun measureLaserFake(): String {
        val mm = fakeLaserMm.removeFirstOrNull() ?: 4000.0
        return measureLaser(mm, "fake_laser", fake = true)
    }

    fun measureTyped(valueMm: Double, explicit: Boolean): String {
        val id = "m_key_${keyCount + 1}"
        val err = bridge.setMeasurement(docHandle, id, valueMm, "typed", null, "wall_s")
        if (err.isNotEmpty()) return err
        bridge.guideNoteKey(guideHandle, "typed", explicit)
        keyCount += 1
        refresh("typed ${valueMm}mm explicit=$explicit")
        return ""
    }

    fun addDoor(): String {
        val err = bridge.addOpening(
            docHandle, storeyId, "wall_s", "op_door", "door", 900.0, 2100.0, 800.0, 0.0,
        )
        if (err.isNotEmpty()) return err
        bridge.guideNoteOpening(guideHandle)
        refresh("placed door")
        return ""
    }

    fun closeRebuildExport(outDir: String): String {
        val closeErr = bridge.closeRoom(docHandle, storeyId, "room_1", "wall_n,wall_e,wall_s,wall_w")
        if (closeErr.isNotEmpty()) return closeErr
        val exports = listOf("glb", "dxf", "pdf")
        for (fmt in exports) {
            val err = bridge.export(docHandle, fmt, "$outDir/room.$fmt")
            if (err.isNotEmpty()) {
                bridge.guideNoteRebuild(guideHandle, false)
                refresh("export $fmt failed: $err")
                return err
            }
        }
        bridge.guideNoteRebuild(guideHandle, true)
        refresh("exported glb/dxf/pdf", exportDir = outDir)
        return ""
    }

    fun runFakeOneRoom(outDir: String): String {
        resetDocument()
        val err = bridge.debugFakeOneRoom(docHandle, guideHandle, outDir)
        if (err.isNotEmpty()) return err
        wallCount = 4
        keyCount = 2
        refresh("fake one-room loop", exportDir = outDir, fake = true, hostOk = true)
        return ""
    }

    private fun resetDocument() {
        if (evidenceHandle != 0L) bridge.evidenceDestroy(evidenceHandle)
        if (guideHandle != 0L) bridge.guideDestroy(guideHandle)
        if (docHandle != 0L) bridge.destroyDocument(docHandle)
        docHandle = bridge.createDocument(documentId)
        guideHandle = bridge.guideCreate()
        evidenceHandle = bridge.evidenceCreate(documentId)
        storeyId = bridge.firstStoreyId(docHandle)
        wallCount = 0
        keyCount = 0
        fakeLaserMm.clear()
        fakeLaserMm.addAll(listOf(4000.0, 3000.0))
    }

    fun attachEmptyEvidenceNote(): String {
        bridge.evidenceAttach(evidenceHandle, "p0_empty", "note", "")
        refresh("evidence attach stub")
        return ""
    }

    fun dispose() {
        if (evidenceHandle != 0L) {
            bridge.evidenceDestroy(evidenceHandle)
            evidenceHandle = 0
        }
        if (guideHandle != 0L) {
            bridge.guideDestroy(guideHandle)
            guideHandle = 0
        }
        if (docHandle != 0L) {
            bridge.destroyDocument(docHandle)
            docHandle = 0
        }
        wallCount = 0
        keyCount = 0
        fakeLaserMm.clear()
        fakeLaserMm.addAll(listOf(4000.0, 3000.0))
    }

    private fun refresh(
        line: String,
        hostOk: Boolean = state.hostOk,
        whitelistOk: Boolean = state.whitelistOk,
        fake: Boolean = state.usingFakeCapture,
        exportDir: String = state.lastExportDir,
    ) {
        val phase = if (guideHandle != 0L) bridge.guidePhase(guideHandle) else "host_check"
        val can = guideHandle != 0L && bridge.guideCanExport(guideHandle)
        val reason = if (guideHandle != 0L) bridge.guideBlockingReason(guideHandle) else ""
        val empty = evidenceHandle == 0L || bridge.evidenceEmpty(evidenceHandle)
        val log = if (state.log.isEmpty()) line else state.log + "\n" + line
        state = GuideUiState(
            phase = phase,
            canExport = can,
            blockingReason = reason,
            hostOk = hostOk,
            usingFakeCapture = fake,
            whitelistOk = whitelistOk,
            log = log,
            lastExportDir = exportDir,
            evidenceEmpty = empty,
        )
    }
}
