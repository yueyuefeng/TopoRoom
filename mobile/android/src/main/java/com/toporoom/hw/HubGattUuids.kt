package com.toporoom.hw

/**
 * TopoRoom hub GATT UUIDs. Must match firmware/toporoom-hub/include/toporoom_hub_protocol.h
 */
object HubGattUuids {
    const val ADV_NAME = "TopoRoom Hub"
    const val SKU = "toporoom_hub_c3"
    const val FW = "0.1.0"
    const val SERVICE = "0000a100-7e90-4c4a-9b1e-746f706f726d"
    const val CHAR_SKU = "0000a101-7e90-4c4a-9b1e-746f706f726d"
    const val CHAR_FW = "0000a102-7e90-4c4a-9b1e-746f706f726d"
    const val CHAR_MEASURE_CMD = "0000a110-7e90-4c4a-9b1e-746f706f726d"
    const val CHAR_LENGTH = "0000a111-7e90-4c4a-9b1e-746f706f726d"
    const val CHAR_BATTERY = "0000a120-7e90-4c4a-9b1e-746f706f726d"
    const val CHAR_STATUS = "0000a121-7e90-4c4a-9b1e-746f706f726d"
    const val CCCD = "00002902-0000-1000-8000-00805f9b34fb"

    const val OP_SINGLE: Int = 0x01
    const val FLAG_REQUIRE_LASER: Int = 0x01
    const val SOURCE_LASER: Int = 1
    const val STATUS_OK: Int = 0
}
