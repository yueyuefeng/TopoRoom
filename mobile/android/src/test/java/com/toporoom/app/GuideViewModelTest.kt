package com.toporoom.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class FakeTopoRoomBridge : TopoRoomBridge {
    var walls = 0
    var openings = 0
    var keys = 0
    var hostOk = false
    var rebuildOk = false
    var lastFakeDir: String? = null
    var failGlb = false
    var lastOpeningKind: String? = null
    var lastHostedKind: String? = null
    var json: String = "{}"
    val saved = mutableMapOf<String, String>()
    private var phase = "host_check"
    private var evidenceEmpty = true
    private var nextHandle = 10L

    override fun version() = "0.1.0"
    override fun createDocument(id: String) = 1L
    override fun destroyDocument(handle: Long) {}
    override fun firstStoreyId(handle: Long) = "storey_1"
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
    ): String {
        walls += 1
        return ""
    }
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
    ): String {
        openings += 1
        lastOpeningKind = kind
        return ""
    }
    override fun setMeasurement(
        handle: Long,
        measurementId: String,
        valueMm: Double,
        source: String,
        instrumentId: String?,
        betweenCsv: String?,
    ): String {
        keys += 1
        return ""
    }
    override fun closeRoom(handle: Long, storeyId: String, roomId: String, wallIdsCsv: String) = ""
    override fun export(handle: Long, format: String, path: String): String {
        if (failGlb && format == "glb") return "glb export rejected"
        return ""
    }
    override fun sceneIrJson(handle: Long) = json
    override fun saveToFile(handle: Long, path: String): String {
        saved[path] = json
        return ""
    }
    override fun loadFromFile(path: String): LoadResult {
        val text = saved[path] ?: return LoadResult(0, "missing")
        json = text
        return LoadResult(nextHandle++, "")
    }
    override fun loadFromJson(json: String): LoadResult {
        this.json = json
        return LoadResult(nextHandle++, "")
    }
    override fun placeHosted(
        handle: Long,
        storeyId: String,
        componentId: String,
        kind: String,
        zBottomMm: Double,
        depthMm: Double,
        hostWallId: String?,
    ): String {
        lastHostedKind = kind
        return ""
    }
    override fun debugFakeOneRoom(doc: Long, guide: Long, outDir: String): String {
        lastFakeDir = outDir
        walls = 4
        openings = 1
        keys = 2
        hostOk = true
        rebuildOk = true
        phase = "export"
        json = SAMPLE_PLAN
        return ""
    }
    override fun runGuidedEdit(doc: Long, guide: Long): String {
        walls = 4
        openings = 1
        keys = 2
        rebuildOk = true
        phase = "export"
        json = SAMPLE_PLAN
        return ""
    }
    override fun guideCreate() = 2L
    override fun guideDestroy(handle: Long) {}
    override fun guideMarkHostOk(handle: Long, ok: Boolean) {
        hostOk = ok
        if (ok && phase == "host_check") phase = "draw_walls"
    }
    override fun guideNoteWall(handle: Long) {
        if (phase == "draw_walls" && walls >= 4) phase = "measure_keys"
    }
    override fun guideNoteOpening(handle: Long) {
        if (phase == "place_openings") phase = "rebuild"
    }
    override fun guideNoteKey(handle: Long, source: String, typedExplicit: Boolean) {
        if (keys >= 2 && phase == "measure_keys") phase = "place_openings"
    }
    override fun guideNoteRebuild(handle: Long, ok: Boolean) {
        rebuildOk = ok
        if (ok) phase = "export"
    }
    override fun guidePhase(handle: Long) = phase
    override fun guideCanExport(handle: Long) = phase == "export"
    override fun guideBlockingReason(handle: Long) = if (phase == "export") "" else phase
    override fun evidenceCreate(documentId: String) = 3L
    override fun evidenceDestroy(handle: Long) {}
    override fun evidenceEmpty(handle: Long) = evidenceEmpty
    override fun evidenceAttach(handle: Long, id: String, kind: String, uri: String): Int {
        evidenceEmpty = false
        return 0
    }
    override fun whitelistAllows(json: String, query: WhitelistQuery) =
        query.phoneModel == "Pixel 8"
    override fun releaseTrainMatches(
        json: String,
        softwareTag: String,
        moduleSku: String,
        firmware: String,
        whitelistVersion: Int,
        hubFirmware: String,
    ) = softwareTag == "0.1.0"

    companion object {
        const val SAMPLE_PLAN = """
        {
          "format": "toporoom.sceneir",
          "version": "0.2",
          "id": "doc_android",
          "units": "mm",
          "revision": 1,
          "storeys": [{
            "id": "storey_1",
            "elevationMm": 0,
            "heightMm": 2800,
            "walls": [{
              "id": "wall_s",
              "kind": "exterior",
              "start": {"x": 0, "y": 0},
              "end": {"x": 4000, "y": 0},
              "thicknessMm": 200,
              "heightMm": 2800,
              "openings": [{
                "id": "op_arch",
                "kind": "archway",
                "widthMm": 1200,
                "heightMm": 2100,
                "offsetMm": 800,
                "sillHeightMm": 0
              }]
            }],
            "rooms": [{
              "id": "room_1",
              "label": "客厅",
              "spaceType": "interior",
              "wallIds": ["wall_s"],
              "clearHeightMm": 2650
            }],
            "hostedComponents": [{
              "id": "hc_beam_1",
              "kind": "beam",
              "params": {"zBottomMm": 2400, "depthMm": 400}
            }]
          }],
          "measurements": [{"id": "m_s", "kind": "length", "valueMm": 4000, "source": "laser"}]
        }
        """
    }
}

class GuideViewModelTest {
    @Test
    fun debugBypassMarksHostOkWhenUnlisted() {
        val bridge = FakeTopoRoomBridge()
        val vm = GuideViewModel(bridge, debugBuild = true)
        vm.start(
            "doc_1",
            "{}",
            WhitelistQuery(phoneModel = "sdk_gphone64_x86_64", androidApi = 34),
            "{}",
        )
        assertTrue(vm.state.hostOk)
        assertTrue(vm.state.usingFakeCapture)
        assertEquals("draw_walls", vm.state.phase)
        assertEquals(AppScreen.HOME, vm.state.screen)
        vm.dispose()
    }

    @Test
    fun fakeOneRoomReachesExport() {
        val bridge = FakeTopoRoomBridge()
        val vm = GuideViewModel(bridge, debugBuild = true)
        vm.start("doc_1", "{}", WhitelistQuery("sdk", 34), "{}")
        assertEquals("", vm.runFakeOneRoom("/tmp/export"))
        assertTrue(vm.state.canExport)
        assertEquals("export", vm.state.phase)
        assertEquals("/tmp/export", bridge.lastFakeDir)
        assertEquals(AppScreen.GUIDE, vm.state.screen)
        assertEquals("archway", vm.state.plan.walls.first().openings.first().kind)
        vm.dispose()
    }

    @Test
    fun stepByStepTypedKeysNeedExplicitFlagOnBridge() {
        val bridge = FakeTopoRoomBridge()
        val vm = GuideViewModel(bridge, debugBuild = true)
        vm.start("doc_1", "{}", WhitelistQuery("Pixel 8", 34), "{}")
        assertFalse(vm.state.usingFakeCapture)
        assertEquals("", vm.addRectangleWalls())
        assertEquals("", vm.measureTyped(4000.0, explicit = true))
        assertEquals("", vm.measureTyped(3000.0, explicit = true))
        assertEquals("", vm.addDoor())
        assertEquals("", vm.closeRebuildExport("/tmp/export"))
        assertTrue(vm.state.canExport)
        vm.dispose()
    }

    @Test
    fun newSchemeOpensGuideAndArchwayHostedExport() {
        val bridge = FakeTopoRoomBridge()
        bridge.failGlb = true
        val vm = GuideViewModel(bridge, debugBuild = true)
        vm.start("doc_1", "{}", WhitelistQuery("sdk", 34), "{}")
        assertEquals("", vm.newScheme("doc_new"))
        assertEquals(AppScreen.GUIDE, vm.state.screen)
        assertEquals("", vm.addOpening("archway"))
        assertEquals("archway", bridge.lastOpeningKind)
        assertEquals("", vm.placeHosted("beam", 2400.0, 400.0))
        assertEquals("beam", bridge.lastHostedKind)
        assertEquals("", vm.exportDeliverables("/tmp/export"))
        assertFalse(vm.state.glbExported)
        assertTrue(vm.state.lastExportFiles.contains("dxf"))
        assertTrue(vm.state.lastExportFiles.contains("pdf"))
        vm.dispose()
    }

    @Test
    fun guidedEditAndSaveLoadRoundTrip() {
        val bridge = FakeTopoRoomBridge()
        val vm = GuideViewModel(bridge, debugBuild = true)
        vm.start("doc_1", "{}", WhitelistQuery("sdk", 34), "{}")
        assertEquals("", vm.runGuidedEdit())
        assertTrue(vm.state.canExport)
        assertEquals("客厅", vm.state.plan.rooms.first().name)
        val path = "/tmp/scheme.sceneir.json"
        assertEquals("", vm.saveScheme(path))
        bridge.json = "{}"
        assertEquals("", vm.loadScheme(path))
        assertEquals("doc_android", vm.state.plan.documentId)
        vm.dispose()
    }
}

class SceneIrPlanParserTest {
    @Test
    fun parsesV02WallsOpeningsClearHeightAndHosted() {
        val plan = SceneIrPlanParser.parse(FakeTopoRoomBridge.SAMPLE_PLAN)
        assertEquals("doc_android", plan.documentId)
        assertEquals(2800.0, plan.storeyHeightMm, 0.01)
        assertEquals(1, plan.walls.size)
        assertEquals("wall_s", plan.walls[0].id)
        assertEquals(4000.0, plan.walls[0].x1, 0.01)
        assertEquals("archway", plan.walls[0].openings[0].kind)
        assertEquals("客厅", plan.rooms[0].name)
        assertEquals(2650.0, plan.rooms[0].clearHeightMm!!, 0.01)
        assertEquals("beam", plan.hosted[0].kind)
        assertEquals(2400.0, plan.hosted[0].zBottomMm, 0.01)
        assertEquals("laser", plan.measurements[0].source)
        assertEquals("垭口", openingKindZh("archway"))
        assertEquals("画墙", phaseLabelZh("draw_walls"))
    }
}

class SchemeFileHelperTest {
    @Test
    fun listedSchemesUseSceneIrSuffix() {
        val dir = File.createTempFile("schemes", "dir").apply {
            delete()
            mkdirs()
            deleteOnExit()
        }
        File(dir, "a.sceneir.json").writeText("{}")
        File(dir, "ignore.txt").writeText("nope")
        val names = dir.listFiles { f -> f.isFile && f.name.endsWith(".sceneir.json") }
            ?.map { it.name.removeSuffix(".sceneir.json") }
            ?.sorted()
        assertEquals(listOf("a"), names)
    }
}
