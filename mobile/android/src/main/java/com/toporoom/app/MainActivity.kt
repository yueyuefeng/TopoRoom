package com.toporoom.app

import android.Manifest
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Bundle
import android.widget.Button
import android.widget.CheckBox
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.toporoom.core.NativeCore
import com.toporoom.hw.DepthSku
import com.toporoom.hw.TopoRoomHubBleClient

class MainActivity : android.app.Activity() {
    private lateinit var model: GuideViewModel
    private lateinit var phaseView: TextView
    private lateinit var reasonView: TextView
    private lateinit var bannerView: TextView
    private lateinit var logView: TextView
    private lateinit var typedValue: EditText
    private lateinit var typedExplicit: CheckBox
    private var hubClient: TopoRoomHubBleClient? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        model = GuideViewModel(JniTopoRoomBridge(), debugBuild = isDebug())

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 32, 32, 32)
        }
        phaseView = TextView(this)
        reasonView = TextView(this)
        bannerView = TextView(this)
        logView = TextView(this)
        typedValue = EditText(this).apply {
            hint = "typed length mm"
            setText("4000")
        }
        typedExplicit = CheckBox(this).apply {
            text = "typed explicit (required for typed keys)"
            isChecked = true
        }

        root.addView(TextView(this).apply { text = "TopoRoom P0 — guided one-room" })
        root.addView(bannerView)
        root.addView(phaseView)
        root.addView(reasonView)
        root.addView(permissionButton())
        root.addView(action("Draw walls (rectangle)") { model.addRectangleWalls() })
        root.addView(action("Measure key (laser Fake/Replay)") { model.measureLaserFake() })
        root.addView(hubScanButton())
        root.addView(hubMeasureButton())
        root.addView(typedValue)
        root.addView(typedExplicit)
        root.addView(action("Measure key (typed)") {
            val mm = typedValue.text.toString().toDoubleOrNull() ?: 4000.0
            model.measureTyped(mm, typedExplicit.isChecked)
        })
        root.addView(action("Place opening (door)") { model.addDoor() })
        root.addView(action("Rebuild + export glb/dxf/pdf") {
            model.closeRebuildExport(exportDir())
        })
        root.addView(action("Run Fake one-room loop") { model.runFakeOneRoom(exportDir()) })
        root.addView(action("Attach empty EvidencePack note") { model.attachEmptyEvidenceNote() })
        root.addView(logView)

        val scroll = ScrollView(this)
        scroll.addView(root)
        setContentView(scroll)

        registerUsbPermissionReceiver()
        startSession()
    }

    override fun onDestroy() {
        hubClient?.disconnect()
        model.dispose()
        super.onDestroy()
    }

    private fun startSession() {
        val whitelist = assets.open("android-whitelist.v1.json").bufferedReader().use { it.readText() }
        val train = assets.open("release-train.v1.json").bufferedReader().use { it.readText() }
        model.start(
            "doc_android",
            whitelist,
            WhitelistQuery(phoneModel = Build.MODEL, androidApi = Build.VERSION.SDK_INT),
            train,
        )
        render()
    }

    private fun permissionButton(): Button {
        val button = Button(this)
        button.text = "Request USB host / Bluetooth permissions"
        button.setOnClickListener {
            requestCapturePermissions()
            appendLog("permission request issued")
        }
        return button
    }

    private fun hubScanButton(): Button {
        val button = Button(this)
        button.text = "Scan / connect TopoRoom hub (BLE laser)"
        button.setOnClickListener {
            requestCapturePermissions()
            if (hubClient == null) hubClient = TopoRoomHubBleClient(this)
            Thread {
                val info = hubClient?.scanAndConnect()
                runOnUiThread {
                    if (info == null) {
                        appendLog("hub: ${hubClient?.lastError ?: "failed"}")
                    } else {
                        appendLog("hub connected ${info.address} sku=${info.sku} fw=${info.firmware}")
                    }
                    render()
                }
            }.start()
        }
        return button
    }

    private fun hubMeasureButton(): Button {
        val button = Button(this)
        button.text = "Measure key (BLE hub laser)"
        button.setOnClickListener {
            val client = hubClient
            if (client?.connectedInfo == null) {
                appendLog("hub not connected — Fake laser still works")
                render()
                return@setOnClickListener
            }
            Thread {
                val mm = client.measureMm()
                runOnUiThread {
                    if (mm == null) {
                        appendLog("hub measure: ${client.lastError}")
                    } else {
                        val err = model.measureLaser(mm, client.connectedInfo?.sku ?: "toporoom_hub_c3", fake = false)
                        if (err.isNotEmpty()) appendLog("error: $err")
                    }
                    render()
                }
            }.start()
        }
        return button
    }

    private fun action(label: String, block: () -> String): Button {
        val button = Button(this)
        button.text = label
        button.setOnClickListener {
            val err = block()
            if (err.isNotEmpty()) appendLog("error: $err")
            render()
        }
        return button
    }

    private fun render() {
        val s = model.state
        phaseView.text = "phase: ${s.phase}  canExport=${s.canExport}"
        reasonView.text = if (s.blockingReason.isEmpty()) "ready" else s.blockingReason
        bannerView.text = when {
            s.usingFakeCapture ->
                "Fake/Replay — emulator/debug. Depth SKU pluggable: fake | dabai_dcw | dual_rgb_uvc."
            s.whitelistOk ->
                "Host on Android whitelist v1 · SKU ${DepthSku.FAKE.id}/${DepthSku.DABAI_DCW.id}/${DepthSku.DUAL_RGB_UVC.id}"
            else -> "Host not listed — capture blocked (debug builds bypass with Fake adapters)"
        }
        logView.text = s.log
    }

    private fun appendLog(line: String) {
        logView.text = logView.text.toString() + "\n" + line
    }

    private fun exportDir(): String {
        val dir = getExternalFilesDir("export") ?: filesDir.resolve("export")
        dir.mkdirs()
        return dir.absolutePath
    }

    private fun isDebug(): Boolean {
        return applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE != 0
    }

    private fun requestCapturePermissions() {
        val needed = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= 31) {
            needed += Manifest.permission.BLUETOOTH_SCAN
            needed += Manifest.permission.BLUETOOTH_CONNECT
        } else {
            needed += Manifest.permission.BLUETOOTH
            needed += Manifest.permission.BLUETOOTH_ADMIN
            needed += Manifest.permission.ACCESS_FINE_LOCATION
        }
        val missing = needed.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, missing.toTypedArray(), REQ_BT)
        }
        requestUsbPermissionIfAttached()
    }

    private fun requestUsbPermissionIfAttached() {
        val usb = getSystemService(USB_SERVICE) as UsbManager
        val device = usb.deviceList.values.firstOrNull() ?: return
        val intent = PendingIntent.getBroadcast(
            this,
            0,
            Intent(ACTION_USB_PERMISSION),
            PendingIntent.FLAG_IMMUTABLE,
        )
        usb.requestPermission(device, intent)
    }

    private fun registerUsbPermissionReceiver() {
        val filter = IntentFilter(ACTION_USB_PERMISSION)
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(usbReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(usbReceiver, filter)
        }
    }

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != ACTION_USB_PERMISSION) return
            val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
            appendLog("usb permission granted=$granted")
        }
    }

    companion object {
        private const val REQ_BT = 42
        private const val ACTION_USB_PERMISSION = "com.toporoom.app.USB_PERMISSION"

        init {
            NativeCore.nativeVersion()
        }
    }
}
