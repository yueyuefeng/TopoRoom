# Linking the official Orbbec Android SDK (Gemini E)

TopoRoom **does not vendor** Orbbec AAR/JNI blobs. Stage-Gate VendorSdk is
`OrbbecGeminiEDepthAdapter` in C++ (port only) plus this host hook.

Locked identity (ADR-001):

| Field | Value |
|-------|--------|
| SKU | `orbbec_gemini_e` |
| USB VID/PID | `0x2BC5` / `0x065C` |
| Camera FW | **3460** (Orbbec Android SDK v1 minimum) |
| Principle | `structured_light` (active stereo IR) |
| IMU | **none** — phone IMU, degraded |
| USB role | Phone = **host**; Gemini E = **device** on OTG or a powered hub |

## 1. Get the SDK legally

1. Read Orbbec’s license: [OrbbecSDK-Android-Wrapper](https://github.com/orbbec/OrbbecSDK-Android-Wrapper).
2. Use the **v1 / `main`** line that lists **Gemini E / firmware 3460**. The v2 Android matrix does **not** list Gemini E — do not assume v2.
3. Download the AAR (and any JNI `.so`) from Orbbec’s GitHub **Releases** or developer portal. Do **not** commit those files here.

## 2. Drop-in (local, gitignored)

```
mobile/android/libs/orbbecsdk-android.aar   # you add this; not in git
```

`local.properties` (not committed):

```properties
sdk.dir=/path/to/Android/sdk
toporoom.orbbec.aar=libs/orbbecsdk-android.aar
```

`build.gradle.kts` sketch (enable only when the AAR is present):

```kotlin
val orbbecAar = providers.gradleProperty("toporoom.orbbec.aar")
dependencies {
    if (orbbecAar.isPresent) {
        implementation(files(orbbecAar.get()))
    }
}
android {
    defaultConfig {
        externalNativeBuild {
            cmake {
                if (orbbecAar.isPresent) {
                    arguments += "-DTOPOROOM_ORBBEC_SDK=ON"
                }
            }
        }
    }
}
```

C++ must still **not** `#include` Orbbec from `core/**/domain/**`. Put SDK calls in
`mobile/android/src/main/cpp/` (or a `hw/` adapter TU) behind `TOPOROOM_ORBBEC_SDK`,
then feed frames into `DepthReplayFixture`-shaped DTOs / `OrbbecGeminiEDepthAdapter`.

Until that flag is on, `OrbbecGeminiE.sdkLinked()` is false and `open()` throws
`NotConnected` with a pointer at this file. CI stays Fake/Replay.

## 3. USB

`res/xml/usb_device_filter.xml` already matches Gemini E. Grant USB Host at
runtime. Prefer a **powered USB hub** (`hubSku=powered_hub_a`); USB2 ~2.3 W
browns out many OTG ports.

## 4. UVC stub

`OrbbecGeminiEUvcStub` exists so the dual-adapter contract is visible.
It is **not** a Stage-Gate pass and **not** a depth principle.
