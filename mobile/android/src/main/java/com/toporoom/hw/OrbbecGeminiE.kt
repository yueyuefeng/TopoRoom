package com.toporoom.hw

/**
 * Host-side Gemini E identity. Real Orbbec SDK symbols live behind
 * [TOPOROOM_ORBBEC_SDK] JNI (see ORBBEC.md). This type never vendors blobs.
 */
object OrbbecGeminiE {
    const val SKU = "orbbec_gemini_e"
    const val VID = 0x2BC5
    const val PID = 0x065C
    const val FIRMWARE = "3460"
    const val PRINCIPLE = "structured_light"
    const val POWER_HINT =
        "USB2 Type-C device on phone OTG; powered_hub_a recommended; no onboard IMU"

    fun sdkLinked(): Boolean = false

    fun openHint(): String =
        "Orbbec SDK not linked. VendorSdk is primary; follow mobile/android/ORBBEC.md. " +
            "UVC is a transport stub only and is not a Stage-Gate pass."
}
