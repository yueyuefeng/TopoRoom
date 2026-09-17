package com.toporoom.hw

import android.annotation.SuppressLint
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.ParcelUuid
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * Real BLE central for the TopoRoom hub GATT laser profile.
 * Does not use RF proximity as a ruler — only length notifies with source=laser.
 *
 * Fake/Replay stay on [com.toporoom.app.GuideViewModel.measureLaserFake].
 */
class TopoRoomHubBleClient(private val context: Context) {
    data class HubInfo(val address: String, val sku: String, val firmware: String)

    @Volatile var lastError: String = ""
        private set
    @Volatile var connectedInfo: HubInfo? = null
        private set

    private var gatt: BluetoothGatt? = null
    private var lengthChar: BluetoothGattCharacteristic? = null
    private var cmdChar: BluetoothGattCharacteristic? = null
    private var notifyLatch: CountDownLatch? = null
    private val lastNotify = AtomicReference<ByteArray?>(null)

    private val adapter
        get() = (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter

    @SuppressLint("MissingPermission")
    fun scanAndConnect(timeoutMs: Long = 8000): HubInfo? {
        lastError = ""
        connectedInfo = null
        val found = AtomicReference<ScanResult?>(null)
        val latch = CountDownLatch(1)
        val scanner = adapter?.bluetoothLeScanner
        if (scanner == null) {
            lastError = "bluetooth adapter missing"
            return null
        }
        val cb = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val name = result.scanRecord?.deviceName ?: result.device.name
                if (name == HubGattUuids.ADV_NAME ||
                    result.scanRecord?.serviceUuids?.any {
                        it.uuid.toString().equals(HubGattUuids.SERVICE, ignoreCase = true)
                    } == true
                ) {
                    found.set(result)
                    latch.countDown()
                }
            }
        }
        val filters = listOf(
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid.fromString(HubGattUuids.SERVICE))
                .build(),
        )
        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()
        scanner.startScan(filters, settings, cb)
        latch.await(timeoutMs, TimeUnit.MILLISECONDS)
        scanner.stopScan(cb)
        val hit = found.get()
        if (hit == null) {
            lastError = "TopoRoom Hub not found"
            return null
        }
        return connectGatt(hit.device.address)
    }

    @SuppressLint("MissingPermission")
    fun connectGatt(address: String): HubInfo? {
        lastError = ""
        val device = adapter?.getRemoteDevice(address)
        if (device == null) {
            lastError = "bad address"
            return null
        }
        val ready = CountDownLatch(1)
        gatt = device.connectGatt(context, false, object : BluetoothGattCallback() {
            override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    g.discoverServices()
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    lastError = "hub disconnected"
                    ready.countDown()
                }
            }

            override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
                val svc = g.getService(UUID.fromString(HubGattUuids.SERVICE))
                if (svc == null) {
                    lastError = "missing TopoRoom GATT service"
                    ready.countDown()
                    return
                }
                cmdChar = svc.getCharacteristic(UUID.fromString(HubGattUuids.CHAR_MEASURE_CMD))
                lengthChar = svc.getCharacteristic(UUID.fromString(HubGattUuids.CHAR_LENGTH))
                lengthChar?.let { enableNotify(g, it) }
                connectedInfo = HubInfo(address, HubGattUuids.SKU, HubGattUuids.FW)
                ready.countDown()
            }

            override fun onCharacteristicChanged(
                g: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
            ) {
                if (characteristic.uuid == UUID.fromString(HubGattUuids.CHAR_LENGTH)) {
                    lastNotify.set(characteristic.value)
                    notifyLatch?.countDown()
                }
            }
        })
        if (!ready.await(8000, TimeUnit.MILLISECONDS) || connectedInfo == null) {
            if (lastError.isEmpty()) lastError = "GATT connect timeout"
            disconnect()
            return null
        }
        return connectedInfo
    }

    @SuppressLint("MissingPermission")
    fun measureMm(timeoutMs: Long = 3000): Double? {
        val g = gatt
        val cmd = cmdChar
        if (g == null || cmd == null) {
            lastError = "hub not connected"
            return null
        }
        lastNotify.set(null)
        notifyLatch = CountDownLatch(1)
        cmd.value = HubGattCodec.packMeasureCmd(timeoutMs = timeoutMs.toInt())
        if (!g.writeCharacteristic(cmd)) {
            lastError = "measure write failed"
            return null
        }
        notifyLatch?.await(timeoutMs + 500, TimeUnit.MILLISECONDS)
        val bytes = lastNotify.get()
        if (bytes == null) {
            lastError = "laser notify timeout"
            return null
        }
        val parsed = HubGattCodec.parseLengthNotify(bytes)
        if (parsed == null) {
            lastError = "bad notify"
            return null
        }
        val mm = HubGattCodec.toLaserMm(parsed)
        if (mm == null) {
            lastError = "notify rejected (not laser / not ok); RF is never a ruler"
            return null
        }
        return mm
    }

    @SuppressLint("MissingPermission")
    fun disconnect() {
        gatt?.disconnect()
        gatt?.close()
        gatt = null
        connectedInfo = null
        cmdChar = null
        lengthChar = null
    }

    @SuppressLint("MissingPermission")
    private fun enableNotify(g: BluetoothGatt, ch: BluetoothGattCharacteristic) {
        g.setCharacteristicNotification(ch, true)
        val cccd = ch.getDescriptor(UUID.fromString(HubGattUuids.CCCD)) ?: return
        cccd.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        g.writeDescriptor(cccd)
    }
}
