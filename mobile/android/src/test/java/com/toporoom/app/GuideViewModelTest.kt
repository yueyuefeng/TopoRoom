package com.toporoom.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class FakeTopoRoomBridge : TopoRoomBridge {
    var walls = 0
    var openings = 0
    var keys = 0
    var hostOk = false
    var rebuildOk = false
    var lastFakeDir: String? = null
    private var phase = "host_check"
    private var evidenceEmpty = true

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
    override fun export(handle: Long, format: String, path: String) = ""
    override fun debugFakeOneRoom(doc: Long, guide: Long, outDir: String): String {
        lastFakeDir = outDir
        walls = 4
        openings = 1
        keys = 2
        hostOk = true
        rebuildOk = true
        phase = "export"
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
    ) = softwareTag == "0.1.0"
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
}
