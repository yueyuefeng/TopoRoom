package com.toporoom.hw

/**
 * Host-side pack/unpack for the TopoRoom hub GATT profile.
 * Golden bytes are locked by core/tests/hub_protocol_test.cpp — keep in sync.
 */
object HubGattCodec {
    data class LengthNotify(
        val lengthMm: Int,
        val status: Int,
        val source: Int,
        val sequence: Int,
        val timestampMs: Long,
    )

    fun packMeasureCmd(
        opcode: Int = HubGattUuids.OP_SINGLE,
        flags: Int = HubGattUuids.FLAG_REQUIRE_LASER,
        timeoutMs: Int = 1000,
    ): ByteArray {
        val t = timeoutMs and 0xFFFF
        return byteArrayOf(
            opcode.toByte(),
            flags.toByte(),
            (t and 0xFF).toByte(),
            ((t shr 8) and 0xFF).toByte(),
        )
    }

    fun parseLengthNotify(bytes: ByteArray): LengthNotify? {
        if (bytes.size < 12) return null
        val mm = readLe32(bytes, 0)
        return LengthNotify(
            lengthMm = mm,
            status = bytes[4].toInt() and 0xFF,
            source = bytes[5].toInt() and 0xFF,
            sequence = readLe16(bytes, 6),
            timestampMs = readLe32(bytes, 8).toLong() and 0xFFFFFFFFL,
        )
    }

    fun toLaserMm(notify: LengthNotify): Double? {
        if (notify.status != HubGattUuids.STATUS_OK) return null
        if (notify.source != HubGattUuids.SOURCE_LASER) return null
        if (notify.lengthMm < 0) return null
        return notify.lengthMm.toDouble()
    }

    fun hex(bytes: ByteArray): String =
        bytes.joinToString("") { b -> "%02X".format(b.toInt() and 0xFF) }

    private fun readLe16(b: ByteArray, o: Int): Int =
        (b[o].toInt() and 0xFF) or ((b[o + 1].toInt() and 0xFF) shl 8)

    private fun readLe32(b: ByteArray, o: Int): Int =
        (b[o].toInt() and 0xFF) or
            ((b[o + 1].toInt() and 0xFF) shl 8) or
            ((b[o + 2].toInt() and 0xFF) shl 16) or
            ((b[o + 3].toInt() and 0xFF) shl 24)
}
