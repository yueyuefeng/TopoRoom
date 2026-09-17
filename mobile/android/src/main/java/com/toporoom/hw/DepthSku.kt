package com.toporoom.hw

/**
 * Pluggable depth SKUs. No Gemini E lock. No claim of a ¥200 ASIC Type-C depth cam.
 * Official vendor blobs are not in git — see DEPTH.md.
 */
enum class DepthSku {
    FAKE,
    DABAI_DCW,
    DUAL_RGB_UVC,
    ;

    val id: String
        get() = when (this) {
            FAKE -> "fake"
            DABAI_DCW -> "dabai_dcw"
            DUAL_RGB_UVC -> "dual_rgb_uvc"
        }

    val firmware: String
        get() = when (this) {
            FAKE -> "replay"
            DABAI_DCW -> "2460"
            DUAL_RGB_UVC -> "uvc_host"
        }

    val asicDepth: Boolean get() = this == DABAI_DCW
    val depthFitLowConfidence: Boolean get() = this == DUAL_RGB_UVC

    companion object {
        const val ORBBEC_VID = 0x2BC5

        fun fromId(sku: String): DepthSku? = values().find { it.id == sku }

        fun openHint(sku: DepthSku): String = when (sku) {
            FAKE -> "Fake/Replay depth — no USB."
            DABAI_DCW ->
                "DaBai DCW (~¥788 ASIC). Link OpenNI/SDK per DEPTH.md. Not a ¥200 Type-C accessory."
            DUAL_RGB_UVC ->
                "Dual RGB UVC assist only. Not ASIC depth. Laser is the millimetre source."
        }
    }
}
