package com.toporoom.hw

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class HubGattCodecTest {
    @Test
    fun measureCommandGoldenBytes() {
        val cmd = HubGattCodec.packMeasureCmd(timeoutMs = 1000)
        assertEquals("0101E803", HubGattCodec.hex(cmd))
    }

    @Test
    fun lengthNotifyGolden900mm() {
        val bytes = byteArrayOf(
            0x84.toByte(), 0x03, 0x00, 0x00,
            0x00, 0x01,
            0x01, 0x00,
            0x00, 0x00, 0x00, 0x00,
        )
        val parsed = HubGattCodec.parseLengthNotify(bytes)!!
        assertEquals(900, parsed.lengthMm)
        assertEquals(1, parsed.source)
        assertEquals(900.0, HubGattCodec.toLaserMm(parsed))
    }

    @Test
    fun rfSourceNeverARuler() {
        val bytes = byteArrayOf(
            0x84.toByte(), 0x03, 0x00, 0x00,
            0x00, 0x00,
            0x01, 0x00,
            0x00, 0x00, 0x00, 0x00,
        )
        val parsed = HubGattCodec.parseLengthNotify(bytes)!!
        assertNull(HubGattCodec.toLaserMm(parsed))
    }
}

class DepthSkuTest {
    @Test
    fun pluggableSkusNoGeminiLock() {
        assertEquals("dabai_dcw", DepthSku.DABAI_DCW.id)
        assertEquals("2460", DepthSku.DABAI_DCW.firmware)
        assertTrue(DepthSku.DABAI_DCW.asicDepth)
        assertEquals("dual_rgb_uvc", DepthSku.DUAL_RGB_UVC.id)
        assertTrue(DepthSku.DUAL_RGB_UVC.depthFitLowConfidence)
        assertFalse(DepthSku.DUAL_RGB_UVC.asicDepth)
        assertEquals("fake", DepthSku.FAKE.id)
        assertNull(DepthSku.fromId("orbbec_gemini_e"))
        assertTrue(DepthSku.openHint(DepthSku.DABAI_DCW).contains("¥788"))
    }
}
