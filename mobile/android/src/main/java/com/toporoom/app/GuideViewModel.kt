package com.toporoom.app

enum class AppScreen { HOME, GUIDE }

data class GuideUiState(
    val phase: String = "host_check",
    val canExport: Boolean = false,
    val blockingReason: String = "",
    val hostOk: Boolean = false,
    val usingFakeCapture: Boolean = false,
    val whitelistOk: Boolean = false,
    val log: String = "",
    val lastExportDir: String = "",
    val lastExportFiles: List<String> = emptyList(),
    val glbExported: Boolean = false,
    val evidenceEmpty: Boolean = true,
    val screen: AppScreen = AppScreen.HOME,
    val plan: PlanSnapshot = PlanSnapshot(),
    val schemes: List<String> = emptyList(),
    val documentId: String = "doc_android",
)

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
    private var openingCount: Int = 0
    private var hostedCount: Int = 0
    private var roomClosed: Boolean = false
    private val fakeLaserMm = ArrayDeque(listOf(4000.0, 3000.0))
    private var schemesDir: String = ""

    fun start(
        documentId: String,
        whitelistJson: String,
        query: WhitelistQuery,
        releaseTrainJson: String,
        schemesDir: String = "",
    ) {
        dispose()
        this.documentId = documentId
        this.schemesDir = schemesDir
        docHandle = bridge.createDocument(documentId)
        guideHandle = bridge.guideCreate()
        evidenceHandle = bridge.evidenceCreate(documentId)
        storeyId = bridge.firstStoreyId(docHandle)
        val listed = bridge.whitelistAllows(whitelistJson, query)
        val trainOk = bridge.releaseTrainMatches(
            releaseTrainJson, "0.1.0", query.moduleSku, query.firmware, 1,
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

    fun showHome() {
        refresh("首页", screen = AppScreen.HOME)
    }

    fun showGuide() {
        refresh("引导量房", screen = AppScreen.GUIDE)
    }

    fun newScheme(id: String = "doc_android"): String {
        documentId = id
        resetDocument()
        bridge.guideMarkHostOk(guideHandle, state.hostOk)
        autoSave()
        refresh("新建方案 $id", screen = AppScreen.GUIDE)
        return ""
    }

    fun addRectangleWalls(): String {
        val rect = listOf(
            Pair("wall_n", doubleArrayOf(0.0, 3000.0, 4000.0, 3000.0)),
            Pair("wall_e", doubleArrayOf(4000.0, 3000.0, 4000.0, 0.0)),
            Pair("wall_s", doubleArrayOf(4000.0, 0.0, 0.0, 0.0)),
            Pair("wall_w", doubleArrayOf(0.0, 0.0, 0.0, 3000.0)),
        )
        for ((id, xy) in rect) {
            val err = bridge.addWall(docHandle, storeyId, id, xy[0], xy[1], xy[2], xy[3], 200.0, 2800.0)
            if (err.isNotEmpty()) return err
            bridge.guideNoteWall(guideHandle)
            wallCount += 1
        }
        syncGuide(rebuildOk = false)
        autoSave()
        refresh("画墙：矩形一室 4000×3000")
        return ""
    }

    fun measureLaserFake(): String {
        val mm = fakeLaserMm.removeFirstOrNull() ?: 4000.0
        val id = "m_key_${keyCount + 1}"
        val err = bridge.setMeasurement(docHandle, id, mm, "laser", "fake_laser", "wall_s")
        if (err.isNotEmpty()) return err
        bridge.guideNoteKey(guideHandle, "laser", false)
        keyCount += 1
        syncGuide(rebuildOk = false)
        autoSave()
        refresh("关键尺寸 Fake激光 ${mm}mm")
        return ""
    }

    fun measureTyped(valueMm: Double, explicit: Boolean): String {
        val id = "m_key_${keyCount + 1}"
        val err = bridge.setMeasurement(docHandle, id, valueMm, "typed", null, "wall_s")
        if (err.isNotEmpty()) return err
        bridge.guideNoteKey(guideHandle, "typed", explicit)
        keyCount += 1
        syncGuide(rebuildOk = false)
        autoSave()
        refresh("关键尺寸 手输 ${valueMm}mm 确认=$explicit")
        return ""
    }

    fun addDoor(): String = addOpening("door")

    fun addOpening(kind: String): String {
        val wallId = "wall_s"
        openingCount += 1
        val id = "op_${kind}_$openingCount"
        val width = when (kind) {
            "window" -> 1200.0
            "archway" -> 1200.0
            else -> 900.0
        }
        val height = when (kind) {
            "window" -> 1400.0
            else -> 2100.0
        }
        val sill = if (kind == "window") 900.0 else 0.0
        val err = bridge.addOpening(
            docHandle, storeyId, wallId, id, kind, width, height, 800.0, sill,
        )
        if (err.isNotEmpty()) {
            openingCount -= 1
            return err
        }
        bridge.guideNoteOpening(guideHandle)
        syncGuide(rebuildOk = false)
        autoSave()
        refresh("放置${openingKindZh(kind)} $id")
        return ""
    }

    fun setStoreyHeight(heightMm: Double, followWalls: Boolean = true): String {
        val err = bridge.setStoreyHeight(docHandle, storeyId, heightMm, followWalls)
        if (err.isNotEmpty()) return err
        autoSave()
        refresh("层高 ${heightMm}mm followWalls=$followWalls")
        return ""
    }

    fun setClearHeight(clearHeightMm: Double, roomId: String = "room_1"): String {
        val closeErr = ensureRoomClosed(roomId)
        if (closeErr.isNotEmpty()) return closeErr
        val err = bridge.setRoomAttributes(
            docHandle, storeyId, roomId, "客厅", "interior", true, clearHeightMm,
        )
        if (err.isNotEmpty()) return err
        autoSave()
        refresh("净高 ${clearHeightMm}mm")
        return ""
    }

    fun placeHosted(kind: String, zBottomMm: Double, depthMm: Double): String {
        hostedCount += 1
        val id = "hc_${kind}_$hostedCount"
        val err = bridge.placeHosted(
            docHandle, storeyId, id, kind, zBottomMm, depthMm, "wall_n",
        )
        if (err.isNotEmpty()) {
            hostedCount -= 1
            return err
        }
        autoSave()
        refresh("放置${hostedKindZh(kind)} $id")
        return ""
    }

    fun rebuild(): String {
        val closeErr = ensureRoomClosed("room_1")
        if (closeErr.isNotEmpty()) return closeErr
        val attrs = bridge.setRoomAttributes(
            docHandle, storeyId, "room_1", "客厅", "interior", true, 2650.0,
        )
        if (attrs.isNotEmpty()) return attrs
        bridge.guideNoteRebuild(guideHandle, true)
        syncGuide(rebuildOk = true)
        autoSave()
        refresh("重建完成")
        return ""
    }

    fun closeRebuildExport(outDir: String): String {
        val closeErr = ensureRoomClosed("room_1")
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
        syncGuide(rebuildOk = true)
        refresh("exported glb/dxf/pdf", exportDir = outDir, files = exports, glbOk = true)
        return ""
    }

    fun exportDeliverables(outDir: String): String {
        val written = mutableListOf<String>()
        var glbOk = false
        for (fmt in listOf("dxf", "pdf", "glb")) {
            val err = bridge.export(docHandle, fmt, "$outDir/room.$fmt")
            if (err.isNotEmpty()) {
                if (fmt == "glb") {
                    refresh("glb 未写出（几何未 OK）: $err")
                    continue
                }
                return err
            }
            written += fmt
            if (fmt == "glb") glbOk = true
        }
        bridge.guideNoteRebuild(guideHandle, true)
        syncGuide(rebuildOk = true)
        autoSave()
        refresh(
            "导出 ${written.joinToString("/")}",
            exportDir = outDir,
            files = written,
            glbOk = glbOk,
        )
        return ""
    }

    fun runFakeOneRoom(outDir: String): String {
        resetDocument()
        bridge.guideMarkHostOk(guideHandle, true)
        val err = bridge.debugFakeOneRoom(docHandle, guideHandle, outDir)
        if (err.isNotEmpty()) return err
        wallCount = 4
        keyCount = 2
        openingCount = 1
        roomClosed = true
        autoSave()
        refresh(
            "Fake 一室回路",
            exportDir = outDir,
            fake = true,
            hostOk = true,
            files = listOf("glb", "dxf", "pdf"),
            glbOk = true,
            screen = AppScreen.GUIDE,
        )
        return ""
    }

    fun runGuidedEdit(): String {
        resetDocument()
        bridge.guideMarkHostOk(guideHandle, state.hostOk || debugBuild)
        val err = bridge.runGuidedEdit(docHandle, guideHandle)
        if (err.isNotEmpty()) return err
        wallCount = 4
        keyCount = 2
        openingCount = 1
        roomClosed = true
        autoSave()
        refresh("引导编辑（墙+垭口+激光关键尺寸）", screen = AppScreen.GUIDE)
        return ""
    }

    fun saveScheme(path: String): String {
        val err = bridge.saveToFile(docHandle, path)
        if (err.isNotEmpty()) return err
        refresh("已保存方案 $path")
        return ""
    }

    fun loadScheme(path: String): String {
        val result = bridge.loadFromFile(path)
        if (result.error.isNotEmpty() || result.handle == 0L) {
            return result.error.ifEmpty { "无法加载方案" }
        }
        adoptDocument(result.handle)
        refresh("已加载方案 $path", screen = AppScreen.GUIDE)
        return ""
    }

    fun loadSchemeJson(json: String): String {
        val result = bridge.loadFromJson(json)
        if (result.error.isNotEmpty() || result.handle == 0L) {
            return result.error.ifEmpty { "无法加载方案" }
        }
        adoptDocument(result.handle)
        refresh("已加载 SceneIR JSON", screen = AppScreen.GUIDE)
        return ""
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
        openingCount = 0
        hostedCount = 0
        roomClosed = false
        fakeLaserMm.clear()
        fakeLaserMm.addAll(listOf(4000.0, 3000.0))
    }

    private fun ensureRoomClosed(roomId: String): String {
        if (roomClosed) return ""
        val closeErr = bridge.closeRoom(docHandle, storeyId, roomId, "wall_n,wall_e,wall_s,wall_w")
        if (closeErr.isNotEmpty()) return closeErr
        roomClosed = true
        return ""
    }

    private fun adoptDocument(handle: Long) {
        val hostOk = state.hostOk
        if (evidenceHandle != 0L) bridge.evidenceDestroy(evidenceHandle)
        if (guideHandle != 0L) bridge.guideDestroy(guideHandle)
        if (docHandle != 0L) bridge.destroyDocument(docHandle)
        docHandle = handle
        guideHandle = bridge.guideCreate()
        documentId = SceneIrPlanParser.parse(bridge.sceneIrJson(docHandle)).documentId.ifEmpty { documentId }
        evidenceHandle = bridge.evidenceCreate(documentId)
        storeyId = bridge.firstStoreyId(docHandle)
        wallCount = 0
        keyCount = 0
        openingCount = 0
        hostedCount = 0
        roomClosed = SceneIrPlanParser.parse(bridge.sceneIrJson(docHandle)).rooms.isNotEmpty()
        fakeLaserMm.clear()
        fakeLaserMm.addAll(listOf(4000.0, 3000.0))
        bridge.guideMarkHostOk(guideHandle, hostOk)
        syncGuide(rebuildOk = roomClosed)
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
        openingCount = 0
        hostedCount = 0
        roomClosed = false
        fakeLaserMm.clear()
        fakeLaserMm.addAll(listOf(4000.0, 3000.0))
    }

    private fun syncGuide(rebuildOk: Boolean) {
        if (guideHandle != 0L && docHandle != 0L) {
            bridge.guideSyncFromDocument(guideHandle, docHandle, rebuildOk)
        }
    }

    private fun autoSave() {
        if (schemesDir.isEmpty() || docHandle == 0L) return
        val path = "$schemesDir/$documentId.sceneir.json"
        bridge.saveToFile(docHandle, path)
    }

    private fun listedSchemes(): List<String> {
        if (schemesDir.isEmpty()) return emptyList()
        val dir = java.io.File(schemesDir)
        if (!dir.isDirectory) return emptyList()
        return dir.listFiles { f -> f.isFile && f.name.endsWith(".sceneir.json") }
            ?.map { it.name.removeSuffix(".sceneir.json") }
            ?.sorted()
            ?: emptyList()
    }

    private fun refresh(
        line: String,
        hostOk: Boolean = state.hostOk,
        whitelistOk: Boolean = state.whitelistOk,
        fake: Boolean = state.usingFakeCapture,
        exportDir: String = state.lastExportDir,
        files: List<String> = state.lastExportFiles,
        glbOk: Boolean = state.glbExported,
        screen: AppScreen = state.screen,
    ) {
        val phase = if (guideHandle != 0L) bridge.guidePhase(guideHandle) else "host_check"
        val can = guideHandle != 0L && bridge.guideCanExport(guideHandle)
        val reason = if (guideHandle != 0L) bridge.guideBlockingReason(guideHandle) else ""
        val empty = evidenceHandle == 0L || bridge.evidenceEmpty(evidenceHandle)
        val json = if (docHandle != 0L) bridge.sceneIrJson(docHandle) else "{}"
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
            lastExportFiles = files,
            glbExported = glbOk,
            evidenceEmpty = empty,
            screen = screen,
            plan = SceneIrPlanParser.parse(json),
            schemes = listedSchemes(),
            documentId = documentId,
        )
    }
}
