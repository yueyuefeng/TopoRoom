package com.toporoom.hw

import org.junit.Assert.assertEquals
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

class OrbbecGeminiETest {
    @Test
    fun skuLockedAndSdkNotVendored() {
        assertEquals("orbbec_gemini_e", OrbbecGeminiE.SKU)
        assertEquals(0x2BC5, OrbbecGeminiE.VID)
        assertEquals(0x065C, OrbbecGeminiE.PID)
        assertEquals("3460", OrbbecGeminiE.FIRMWARE)
        assertTrue(!OrbbecGeminiE.sdkLinked())
        assertTrue(OrbbecGeminiE.openHint().contains("ORBBEC.md"))
    }
}
