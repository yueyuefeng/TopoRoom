package com.toporoom.app

import android.Manifest
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Typeface
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.Button
import android.widget.CheckBox
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.toporoom.core.NativeCore
import java.io.File

class MainActivity : android.app.Activity() {
    private lateinit var model: GuideViewModel
    private lateinit var homeRoot: LinearLayout
    private lateinit var guideRoot: LinearLayout
    private lateinit var homeBanner: TextView
    private lateinit var homePhase: TextView
    private lateinit var homeList: LinearLayout
    private lateinit var homeCanvas: PlanCanvasView
    private lateinit var guideBanner: TextView
    private lateinit var guidePhase: TextView
    private lateinit var guideReason: TextView
    private lateinit var guideSteps: TextView
    private lateinit var guideCanvas: PlanCanvasView
    private lateinit var guideLog: TextView
    private lateinit var typedValue: EditText
    private lateinit var typedExplicit: CheckBox
    private lateinit var storeyHeightInput: EditText
    private lateinit var clearHeightInput: EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        model = GuideViewModel(JniTopoRoomBridge(), debugBuild = isDebug())

        val host = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFFFAFAF7.toInt())
        }
        homeRoot = buildHome()
        guideRoot = buildGuide()
        guideRoot.visibility = View.GONE
        host.addView(homeRoot, LinearLayout.LayoutParams(MATCH, MATCH))
        host.addView(guideRoot, LinearLayout.LayoutParams(MATCH, MATCH))
        setContentView(host)

        registerUsbPermissionReceiver()
        seedSampleScheme()
        startSession()
    }

    override fun onDestroy() {
        runCatching { unregisterReceiver(usbReceiver) }
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
            schemesDir().absolutePath,
        )
        render()
    }

    private fun buildHome(): LinearLayout {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(20), dp(20), dp(20))
        }
        val scroll = ScrollView(this)
        val col = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }

        col.addView(titleView("拓间 TopoRoom"))
        col.addView(subTitleView("遗留 JNI 壳 · 户型图 · 量房会话 · Fake/Replay"))
        col.addView(bodyView().apply {
            text = "P0 APK 请用 godot/ 导出。本页仅 JNI / Fake 测试。"
        })
        homeBanner = bodyView()
        homePhase = bodyView()
        col.addView(homeBanner)
        col.addView(homePhase)

        col.addView(action("新建方案") {
            model.newScheme("doc_${System.currentTimeMillis() % 100000}")
        })
        col.addView(action("引导量房") { model.showGuide(); "" })
        col.addView(action("Fake 一室") { model.runFakeOneRoom(exportDir()) })
        col.addView(action("导出 DXF/PDF（glb 若 OK）") { model.exportDeliverables(exportDir()) })
        col.addView(action("申请 USB / 蓝牙 / 附近设备权限") {
            requestCapturePermissions()
            "permission request issued"
        })

        col.addView(section("方案列表"))
        homeList = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        col.addView(homeList)

        homeCanvas = PlanCanvasView(this).apply {
            layoutParams = LinearLayout.LayoutParams(MATCH, dp(280)).apply { topMargin = dp(12) }
        }
        col.addView(homeCanvas)
        scroll.addView(col)
        root.addView(scroll, LinearLayout.LayoutParams(MATCH, MATCH))
        return root
    }

    private fun buildGuide(): LinearLayout {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
        }
        val scroll = ScrollView(this)
        val col = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }

        col.addView(titleView("引导量房"))
        col.addView(action("← 返回首页") { model.showHome(); "" })
        guideSteps = bodyView()
        guideBanner = bodyView()
        guidePhase = bodyView()
        guideReason = bodyView()
        col.addView(guideSteps)
        col.addView(guideBanner)
        col.addView(guidePhase)
        col.addView(guideReason)

        col.addView(section("1. 画墙"))
        col.addView(action("画墙（矩形一室 4000×3000）") { model.addRectangleWalls() })

        col.addView(section("2. 门窗洞 / 垭口"))
        val openings = LinearLayout(this)
        openings.addView(action("门洞") { model.addOpening("door") }, flex())
        openings.addView(action("窗洞") { model.addOpening("window") }, flex())
        openings.addView(action("垭口") { model.addOpening("archway") }, flex())
        col.addView(openings)

        col.addView(section("3. 关键尺寸（Fake 激光或手输）"))
        col.addView(action("Fake 激光关键尺寸") { model.measureLaserFake() })
        typedValue = EditText(this).apply {
            hint = "手输长度 mm"
            setText("4000")
            inputType = android.text.InputType.TYPE_CLASS_NUMBER or
                android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL
        }
        typedExplicit = CheckBox(this).apply {
            text = "手输确认（typed explicit）"
            isChecked = true
        }
        col.addView(typedValue)
        col.addView(typedExplicit)
        col.addView(action("手输关键尺寸") {
            val mm = typedValue.text.toString().toDoubleOrNull() ?: 4000.0
            model.measureTyped(mm, typedExplicit.isChecked)
        })

        col.addView(section("4. 层高 / 净高 / 梁柱烟道"))
        storeyHeightInput = EditText(this).apply {
            hint = "层高 mm"
            setText("2800")
            inputType = android.text.InputType.TYPE_CLASS_NUMBER
        }
        clearHeightInput = EditText(this).apply {
            hint = "净高 mm"
            setText("2650")
            inputType = android.text.InputType.TYPE_CLASS_NUMBER
        }
        col.addView(storeyHeightInput)
        col.addView(action("设置层高") {
            model.setStoreyHeight(storeyHeightInput.text.toString().toDoubleOrNull() ?: 2800.0)
        })
        col.addView(clearHeightInput)
        col.addView(action("设置净高") {
            model.setClearHeight(clearHeightInput.text.toString().toDoubleOrNull() ?: 2650.0)
        })
        val hosted = LinearLayout(this)
        hosted.addView(action("梁") { model.placeHosted("beam", 2400.0, 400.0) }, flex())
        hosted.addView(action("柱") { model.placeHosted("column", 0.0, 400.0) }, flex())
        hosted.addView(action("烟道") { model.placeHosted("flue", 0.0, 400.0) }, flex())
        col.addView(hosted)

        col.addView(section("5. 重建 → 导出"))
        col.addView(action("重建") { model.rebuild() })
        col.addView(action("导出 DXF/PDF（glb 若 OK）") { model.exportDeliverables(exportDir()) })
        col.addView(action("一键引导编辑（C API GuidedEdit）") { model.runGuidedEdit() })
        col.addView(action("Fake 一室回路") { model.runFakeOneRoom(exportDir()) })
        col.addView(action("保存方案") {
            val path = File(schemesDir(), "${model.documentId}.sceneir.json").absolutePath
            model.saveScheme(path)
        })

        guideCanvas = PlanCanvasView(this).apply {
            layoutParams = LinearLayout.LayoutParams(MATCH, dp(280)).apply { topMargin = dp(8) }
        }
        col.addView(guideCanvas)
        guideLog = TextView(this).apply {
            typeface = Typeface.MONOSPACE
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setPadding(0, dp(8), 0, 0)
        }
        col.addView(guideLog)

        scroll.addView(col)
        root.addView(scroll, LinearLayout.LayoutParams(MATCH, MATCH))
        return root
    }

    private fun render() {
        val s = model.state
        val banner = when {
            s.usingFakeCapture ->
                "Fake/Replay 量房 — 模拟器/调试包，无需深度模组或蓝牙激光。"
            s.whitelistOk -> "主机在 Android 白名单 v1"
            else -> "主机未列入白名单 — 量房被拦截（调试包以 Fake 适配器放行）"
        }
        val phaseLine = "阶段：${phaseLabelZh(s.phase)}（${s.phase}）  可导出=${s.canExport}"
        val reason = if (s.canExport) "可以进行导出" else blockingReasonZh(s.blockingReason)
        val steps = "画墙 → 门窗洞/垭口 → 关键尺寸 → 重建 → 导出"

        homeBanner.text = banner
        homePhase.text = phaseLine + "\n" + reason
        if (s.lastExportDir.isNotEmpty()) {
            homePhase.append("\n导出目录：${s.lastExportDir}")
            if (s.lastExportFiles.isNotEmpty()) {
                homePhase.append("  文件=${s.lastExportFiles.joinToString(",")}")
            }
            if (!s.glbExported && s.lastExportFiles.isNotEmpty()) {
                homePhase.append("（glb 未写出）")
            }
        }
        homeCanvas.snapshot = s.plan
        homeList.removeAllViews()
        if (s.schemes.isEmpty()) {
            homeList.addView(bodyView().apply { text = "尚无已保存方案" })
        } else {
            for (id in s.schemes) {
                homeList.addView(action("加载 $id") {
                    model.loadScheme(File(schemesDir(), "$id.sceneir.json").absolutePath)
                })
            }
        }

        guideBanner.text = banner
        guidePhase.text = phaseLine
        guideReason.text = reason
        guideSteps.text = steps
        guideCanvas.snapshot = s.plan
        guideLog.text = s.log

        val onHome = s.screen == AppScreen.HOME
        homeRoot.visibility = if (onHome) View.VISIBLE else View.GONE
        guideRoot.visibility = if (onHome) View.GONE else View.VISIBLE
    }

    private fun action(label: String, block: () -> String): Button {
        val button = Button(this)
        button.text = label
        button.isAllCaps = false
        button.setOnClickListener {
            val err = block()
            if (err.isNotEmpty()) {
                val extra = "error: $err"
                guideLog.text = (guideLog.text?.toString() ?: "") + "\n" + extra
            }
            render()
        }
        return button
    }

    private fun titleView(text: String) = TextView(this).apply {
        this.text = text
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
        setTypeface(typeface, Typeface.BOLD)
        setPadding(0, 0, 0, dp(4))
    }

    private fun subTitleView(text: String) = TextView(this).apply {
        this.text = text
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
        setPadding(0, 0, 0, dp(8))
    }

    private fun section(text: String) = TextView(this).apply {
        this.text = text
        setTypeface(typeface, Typeface.BOLD)
        setPadding(0, dp(12), 0, dp(4))
    }

    private fun bodyView() = TextView(this).apply {
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        setPadding(0, dp(2), 0, dp(2))
    }

    private fun flex() = LinearLayout.LayoutParams(0, WRAP, 1f)

    private fun seedSampleScheme() {
        val dest = File(schemesDir(), "sample_rect_room.sceneir.json")
        if (dest.exists()) return
        runCatching {
            assets.open("rect-room-v02-archway-clearheight.sceneir.json").use { input ->
                dest.outputStream().use { input.copyTo(it) }
            }
        }
    }

    private fun schemesDir(): File {
        val dir = File(filesDir, "schemes")
        dir.mkdirs()
        return dir
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
        if (Build.VERSION.SDK_INT >= 33) {
            needed += Manifest.permission.NEARBY_WIFI_DEVICES
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
            guideLog.text = (guideLog.text?.toString() ?: "") + "\nusb permission granted=$granted"
        }
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    companion object {
        private const val MATCH = LinearLayout.LayoutParams.MATCH_PARENT
        private const val WRAP = LinearLayout.LayoutParams.WRAP_CONTENT
        private const val REQ_BT = 42
        private const val ACTION_USB_PERMISSION = "com.toporoom.app.USB_PERMISSION"

        init {
            NativeCore.nativeVersion()
        }
    }
}
