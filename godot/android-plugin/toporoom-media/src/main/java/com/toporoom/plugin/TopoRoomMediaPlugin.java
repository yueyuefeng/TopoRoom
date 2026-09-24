package com.toporoom.plugin;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ClipData;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.opengl.GLES20;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.SystemClock;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Gallery + camera Intents. Gallery chain (Chinese OEMs often stub Photo Picker):
 *   ACTION_GET_CONTENT image/*  (first on Huawei / Xiaomi / OPPO / vivo / …)
 *   → ACTION_GET_CONTENT without CATEGORY_OPENABLE
 *   → ACTION_PICK MediaStore.Images (needs READ_MEDIA_IMAGES)
 *   → ACTION_OPEN_DOCUMENT
 *   → ACTION_PICK_IMAGES last on CN OEMs (first on Pixel / API 33+)
 * Copies content:// into app cache so Godot FileAccess can read it.
 */
public class TopoRoomMediaPlugin extends GodotPlugin {
    private static final String TAG = "TopoRoomMedia";
    private static final String PLUGIN_NAME = "TopoRoomMedia";
    private static final int REQ_CAMERA = 4101;
    private static final int REQ_GALLERY = 4102;
    private static final int REQ_CAMERA_PERM = 4103;
    private static final int REQ_READ_IMAGES = 4104;
    private static final long QUICK_CANCEL_MS = 450L;

    private static final SignalInfo IMAGE_PICKED = new SignalInfo("image_picked", String.class);
    private static final SignalInfo PICK_CANCELLED = new SignalInfo("pick_cancelled");
    private static final SignalInfo PICK_ERROR = new SignalInfo("pick_error", String.class);
    private static final SignalInfo AR_STATUS = new SignalInfo("ar_status", String.class);

    @Nullable private File pendingPhoto;
    private boolean cameraAwaitingResult;
    private boolean cameraEmitted;
    private int galleryAttempt;
    private long galleryLaunchedAt;
    private boolean awaitingReadPerm;
    @Nullable private Object arSession;
    private int arTexId;

    public TopoRoomMediaPlugin(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return PLUGIN_NAME;
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(IMAGE_PICKED, PICK_CANCELLED, PICK_ERROR, AR_STATUS));
    }

    @NonNull
    @Override
    public List<String> getPluginMethods() {
        return Arrays.asList(
                "capture_photo", "pick_gallery",
                "ar_available", "ar_start", "ar_hit_center", "ar_stop");
    }

    @UsedByGodot
    public void capture_photo() {
        runOnUiThread(this::launchCamera);
    }

    @UsedByGodot
    public void pick_gallery() {
        galleryAttempt = 0;
        awaitingReadPerm = false;
        runOnUiThread(this::launchGallery);
    }

    /**
     * Optional ARCore (reflection — no compile-time import). Phone-camera planes
     * only; never requires a LiDAR accessory. Missing / unsupported → "unsupported"
     * so GDScript can degrade to guided measure + demo room.
     */
    @UsedByGodot
    @NonNull
    public String ar_available() {
        Activity activity = getActivity();
        if (activity == null) {
            return "no_activity";
        }
        try {
            Class<?> apkCl = Class.forName("com.google.ar.core.ArCoreApk");
            Object apk = apkCl.getMethod("getInstance").invoke(null);
            Object avail = apkCl.getMethod("checkAvailability", Context.class).invoke(apk, activity);
            String name = String.valueOf(avail);
            if (name.contains("SUPPORTED_INSTALLED")) {
                return "ok";
            }
            if (name.contains("SUPPORTED_APK_TOO_OLD") || name.contains("SUPPORTED_NOT_INSTALLED")) {
                return "install";
            }
            if (name.contains("UNKNOWN_CHECKING") || name.contains("UNKNOWN_TIMED_OUT")
                    || name.contains("UNKNOWN_ERROR")) {
                return "unknown";
            }
            return "unsupported";
        } catch (ClassNotFoundException e) {
            return "missing_sdk";
        } catch (Throwable t) {
            Log.w(TAG, "ar_available", t);
            return "error";
        }
    }

    @UsedByGodot
    @NonNull
    public String ar_start() {
        Activity activity = getActivity();
        if (activity == null) {
            return "no_activity";
        }
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA)
                != PackageManager.PERMISSION_GRANTED) {
            return "need_camera";
        }
        try {
            ar_stop();
            Class<?> sessionCl = Class.forName("com.google.ar.core.Session");
            Object session = sessionCl.getConstructor(Context.class).newInstance(activity);
            Class<?> configCl = Class.forName("com.google.ar.core.Config");
            Object config = configCl.getConstructor(sessionCl).newInstance(session);
            Class<?> planeMode = Class.forName("com.google.ar.core.Config$PlaneFindingMode");
            Object horizontal = Enum.valueOf(planeMode.asSubclass(Enum.class), "HORIZONTAL");
            configCl.getMethod("setPlaneFindingMode", planeMode).invoke(config, horizontal);
            Class<?> updateMode = Class.forName("com.google.ar.core.Config$UpdateMode");
            try {
                Object latest = Enum.valueOf(updateMode.asSubclass(Enum.class), "LATEST_CAMERA_IMAGE");
                configCl.getMethod("setUpdateMode", updateMode).invoke(config, latest);
            } catch (Throwable ignored) {
            }
            sessionCl.getMethod("configure", configCl).invoke(session, config);
            if (arTexId == 0) {
                int[] tex = new int[1];
                GLES20.glGenTextures(1, tex, 0);
                arTexId = tex[0];
            }
            if (arTexId != 0) {
                sessionCl.getMethod("setCameraTextureName", int.class).invoke(session, arTexId);
            }
            android.util.DisplayMetrics dm = activity.getResources().getDisplayMetrics();
            int rot = activity.getWindowManager().getDefaultDisplay().getRotation();
            sessionCl.getMethod("setDisplayGeometry", int.class, int.class, int.class)
                    .invoke(session, rot, dm.widthPixels, dm.heightPixels);
            sessionCl.getMethod("resume").invoke(session);
            arSession = session;
            emitSignalOnRender("ar_status", "started");
            Log.i(TAG, "ar_start ok tex=" + arTexId);
            return "ok";
        } catch (ClassNotFoundException e) {
            return "missing_sdk";
        } catch (Throwable t) {
            Log.w(TAG, "ar_start", t);
            arSession = null;
            return "error";
        }
    }

    @UsedByGodot
    @NonNull
    public String ar_hit_center() {
        if (arSession == null) {
            return "no_session";
        }
        Activity activity = getActivity();
        if (activity == null) {
            return "no_activity";
        }
        try {
            Class<?> sessionCl = arSession.getClass();
            android.util.DisplayMetrics dm = activity.getResources().getDisplayMetrics();
            int rot = activity.getWindowManager().getDefaultDisplay().getRotation();
            sessionCl.getMethod("setDisplayGeometry", int.class, int.class, int.class)
                    .invoke(arSession, rot, dm.widthPixels, dm.heightPixels);
            Object frame = sessionCl.getMethod("update").invoke(arSession);
            float cx = dm.widthPixels * 0.5f;
            float cy = dm.heightPixels * 0.42f;
            @SuppressWarnings("unchecked")
            List<Object> hits = (List<Object>) frame.getClass()
                    .getMethod("hitTest", float.class, float.class)
                    .invoke(frame, cx, cy);
            if (hits == null || hits.isEmpty()) {
                return "miss";
            }
            Object pose = hits.get(0).getClass().getMethod("getHitPose").invoke(hits.get(0));
            float x = ((Number) pose.getClass().getMethod("tx").invoke(pose)).floatValue();
            float z = ((Number) pose.getClass().getMethod("tz").invoke(pose)).floatValue();
            return String.format(Locale.US, "ok,%.4f,%.4f", x, z);
        } catch (Throwable t) {
            Log.w(TAG, "ar_hit_center", t);
            return "error";
        }
    }

    @UsedByGodot
    public void ar_stop() {
        Object session = arSession;
        arSession = null;
        if (session == null) {
            return;
        }
        try {
            session.getClass().getMethod("pause").invoke(session);
        } catch (Throwable ignored) {
        }
        try {
            session.getClass().getMethod("close").invoke(session);
        } catch (Throwable ignored) {
        }
        emitSignalOnRender("ar_status", "stopped");
    }

    private void launchCamera() {
        Activity activity = getActivity();
        if (activity == null) {
            emitError("no activity");
            return;
        }
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                    activity, new String[] {Manifest.permission.CAMERA}, REQ_CAMERA_PERM);
            return;
        }
        try {
            File dir = cameraOutputDir(activity);
            if (!dir.exists() && !dir.mkdirs()) {
                emitError("cannot create camera dir");
                return;
            }
            pendingPhoto = new File(dir, "capture_" + System.currentTimeMillis() + ".jpg");
            if (!pendingPhoto.exists() && !pendingPhoto.createNewFile()) {
                emitError("cannot create capture file");
                return;
            }
            Uri uri = FileProvider.getUriForFile(
                    activity, activity.getPackageName() + ".fileprovider", pendingPhoto);
            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
            intent.putExtra("return-data", false);
            intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    | Intent.FLAG_GRANT_READ_URI_PERMISSION);
            intent.setClipData(ClipData.newRawUri("", uri));
            List<ResolveInfo> cameras = activity.getPackageManager()
                    .queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);
            for (ResolveInfo info : cameras) {
                if (info.activityInfo == null) {
                    continue;
                }
                activity.grantUriPermission(
                        info.activityInfo.packageName,
                        uri,
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION | Intent.FLAG_GRANT_READ_URI_PERMISSION);
            }
            cameraAwaitingResult = true;
            cameraEmitted = false;
            Log.i(TAG, "camera launch resolvers=" + cameras.size()
                    + " file=" + pendingPhoto.getAbsolutePath());
            activity.startActivityForResult(intent, REQ_CAMERA);
        } catch (ActivityNotFoundException e) {
            cameraAwaitingResult = false;
            pendingPhoto = null;
            emitError("no camera app");
        } catch (Exception e) {
            cameraAwaitingResult = false;
            pendingPhoto = null;
            Log.e(TAG, "capture_photo", e);
            emitError(e.getMessage() == null ? "camera failed" : e.getMessage());
        }
    }

    private void launchGallery() {
        Activity activity = getActivity();
        if (activity == null) {
            emitError("no activity");
            return;
        }
        List<Intent> chain = galleryChain();
        while (galleryAttempt < chain.size()) {
            Intent intent = chain.get(galleryAttempt);
            galleryAttempt++;
            if (intent == null) {
                continue;
            }
            if (needsReadPermission(intent) && !hasReadImages(activity)) {
                awaitingReadPerm = true;
                galleryAttempt--;
                requestReadImages(activity);
                return;
            }
            Log.i(TAG, "gallery launch " + intent.getAction()
                    + " attempt=" + galleryAttempt + "/" + chain.size());
            if (startGalleryIntent(activity, intent)) {
                return;
            }
            Log.w(TAG, "gallery not found " + intent.getAction());
        }
        emitError("no gallery");
    }

    private boolean startGalleryIntent(@NonNull Activity activity, @NonNull Intent intent) {
        String action = intent.getAction();
        try {
            galleryLaunchedAt = SystemClock.elapsedRealtime();
            activity.startActivityForResult(intent, REQ_GALLERY);
            return true;
        } catch (ActivityNotFoundException e) {
            if (MediaStore.ACTION_PICK_IMAGES.equals(action)) {
                return false;
            }
            try {
                galleryLaunchedAt = SystemClock.elapsedRealtime();
                activity.startActivityForResult(
                        Intent.createChooser(intent, "选择户型图"), REQ_GALLERY);
                return true;
            } catch (ActivityNotFoundException e2) {
                return false;
            }
        } catch (Exception e) {
            Log.e(TAG, "pick_gallery", e);
            return false;
        }
    }

    @NonNull
    private List<Intent> galleryChain() {
        List<Intent> chain = new ArrayList<>();
        boolean cn = isChineseOem();
        if (!cn && Build.VERSION.SDK_INT >= 33) {
            chain.add(photoPickerIntent());
        }
        chain.add(getContentIntent(true));
        chain.add(getContentIntent(false));
        chain.add(mediaStorePickIntent());
        chain.add(openDocumentIntent());
        if (cn || Build.VERSION.SDK_INT < 33) {
            chain.add(photoPickerIntent());
        }
        return chain;
    }

    @NonNull
    private static Intent photoPickerIntent() {
        Intent intent = new Intent(MediaStore.ACTION_PICK_IMAGES);
        if (Build.VERSION.SDK_INT >= 33) {
            intent.putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, 1);
        }
        return intent;
    }

    @NonNull
    private static Intent getContentIntent(boolean openable) {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        if (openable) {
            intent.addCategory(Intent.CATEGORY_OPENABLE);
        }
        intent.setType("image/*");
        intent.putExtra(Intent.EXTRA_MIME_TYPES, new String[] {
                "image/jpeg", "image/png", "image/webp", "image/*"
        });
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
        intent.putExtra(Intent.EXTRA_LOCAL_ONLY, false);
        return intent;
    }

    @NonNull
    private static Intent mediaStorePickIntent() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        intent.setType("image/*");
        return intent;
    }

    @NonNull
    private static Intent openDocumentIntent() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("image/*");
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION
                | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
        return intent;
    }

    private static boolean needsReadPermission(@NonNull Intent intent) {
        return Intent.ACTION_PICK.equals(intent.getAction());
    }

    private static boolean hasReadImages(@NonNull Activity activity) {
        if (Build.VERSION.SDK_INT >= 33) {
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_MEDIA_IMAGES)
                    == PackageManager.PERMISSION_GRANTED) {
                return true;
            }
            if (Build.VERSION.SDK_INT >= 34) {
                return ContextCompat.checkSelfPermission(
                                activity, "android.permission.READ_MEDIA_VISUAL_USER_SELECTED")
                        == PackageManager.PERMISSION_GRANTED;
            }
            return false;
        }
        return ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_EXTERNAL_STORAGE)
                == PackageManager.PERMISSION_GRANTED;
    }

    private void requestReadImages(@NonNull Activity activity) {
        List<String> perms = new ArrayList<>();
        if (Build.VERSION.SDK_INT >= 33) {
            perms.add(Manifest.permission.READ_MEDIA_IMAGES);
            if (Build.VERSION.SDK_INT >= 34) {
                perms.add("android.permission.READ_MEDIA_VISUAL_USER_SELECTED");
            }
        } else {
            perms.add(Manifest.permission.READ_EXTERNAL_STORAGE);
        }
        ActivityCompat.requestPermissions(
                activity, perms.toArray(new String[0]), REQ_READ_IMAGES);
    }

    private static boolean isChineseOem() {
        String m = String.valueOf(Build.MANUFACTURER).toLowerCase(Locale.US);
        String b = String.valueOf(Build.BRAND).toLowerCase(Locale.US);
        String s = m + " " + b;
        return s.contains("huawei") || s.contains("honor") || s.contains("xiaomi")
                || s.contains("redmi") || s.contains("oppo") || s.contains("vivo")
                || s.contains("realme") || s.contains("oneplus") || s.contains("meizu")
                || s.contains("lenovo") || s.contains("zte") || s.contains("nubia")
                || s.contains("iqoo") || s.contains("blackshark");
    }

    @Override
    public void onMainRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == REQ_CAMERA_PERM) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                launchCamera();
            } else {
                emitError("需要相机权限才能拍照");
            }
            return;
        }
        if (requestCode == REQ_READ_IMAGES) {
            awaitingReadPerm = false;
            Activity activity = getActivity();
            if (activity == null || !hasReadImages(activity)) {
                Log.w(TAG, "READ_MEDIA_IMAGES denied, skip ACTION_PICK");
                galleryAttempt++;
            }
            launchGallery();
        }
    }

    @Override
    public void onMainResume() {
        if (!cameraAwaitingResult || cameraEmitted) {
            return;
        }
        if (emitPendingCameraFileIfWritten()) {
            Log.i(TAG, "camera file present on resume");
            finishCamera(null, true);
        }
    }

    @Override
    public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != REQ_CAMERA && requestCode != REQ_GALLERY) {
            return;
        }
        if (requestCode == REQ_CAMERA) {
            if (cameraEmitted) {
                return;
            }
            boolean ok = resultCode == Activity.RESULT_OK || emitPendingCameraFileIfWritten();
            if (ok) {
                finishCamera(data, true);
                return;
            }
            cameraAwaitingResult = false;
            pendingPhoto = null;
            emitSignalOnRender("pick_cancelled");
            return;
        }
        if (resultCode != Activity.RESULT_OK) {
            long dt = SystemClock.elapsedRealtime() - galleryLaunchedAt;
            if (dt < QUICK_CANCEL_MS) {
                Log.w(TAG, "gallery quick-cancel " + dt + "ms, trying next");
                launchGallery();
                return;
            }
            emitSignalOnRender("pick_cancelled");
            return;
        }
        handleGalleryResult(data);
    }

    private void finishCamera(@Nullable Intent data, boolean ok) {
        if (cameraEmitted) {
            return;
        }
        cameraAwaitingResult = false;
        cameraEmitted = true;
        if (ok) {
            handleCameraResult(data);
        }
    }

    private boolean emitPendingCameraFileIfWritten() {
        return pendingPhoto != null && pendingPhoto.exists() && pendingPhoto.length() > 32;
    }

    private void handleCameraResult(@Nullable Intent data) {
        if (pendingPhoto != null && pendingPhoto.exists() && pendingPhoto.length() > 0) {
            File src = pendingPhoto;
            pendingPhoto = null;
            emitCameraFile(src);
            return;
        }
        if (data != null && data.getData() != null) {
            copyAndEmit(data.getData());
            return;
        }
        if (data != null && data.getExtras() != null) {
            Object blob = data.getExtras().get("data");
            if (blob instanceof Bitmap) {
                saveBitmapAndEmit((Bitmap) blob);
                return;
            }
        }
        pendingPhoto = null;
        emitError("camera returned no image");
    }

    private void emitCameraFile(@NonNull File src) {
        BitmapFactory.Options bounds = new BitmapFactory.Options();
        bounds.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(src.getAbsolutePath(), bounds);
        int maxDim = Math.max(bounds.outWidth, bounds.outHeight);
        Bitmap bmp = null;
        if (maxDim > 0) {
            int sample = 1;
            while (maxDim / sample > 4096) {
                sample *= 2;
            }
            BitmapFactory.Options opts = new BitmapFactory.Options();
            opts.inSampleSize = Math.max(sample, 1);
            bmp = BitmapFactory.decodeFile(src.getAbsolutePath(), opts);
        }
        Activity activity = getActivity();
        if (bmp != null && activity != null) {
            File dest = new File(cacheImportsDir(activity), "capture_" + System.currentTimeMillis() + ".jpg");
            try (FileOutputStream out = new FileOutputStream(dest)) {
                bmp.compress(Bitmap.CompressFormat.JPEG, 92, out);
                bmp.recycle();
                if (dest.exists() && dest.length() >= 32) {
                    emitPath(dest.getAbsolutePath());
                    return;
                }
            } catch (Exception e) {
                bmp.recycle();
                Log.w(TAG, "camera recompress", e);
            }
        } else if (bmp != null) {
            bmp.recycle();
        }
        emitPath(src.getAbsolutePath());
    }

    private void handleGalleryResult(@Nullable Intent data) {
        if (data == null) {
            emitError("gallery returned no image");
            return;
        }
        Uri uri = data.getData();
        if (uri == null && data.getClipData() != null && data.getClipData().getItemCount() > 0) {
            uri = data.getClipData().getItemAt(0).getUri();
        }
        if (uri == null && data.getExtras() != null) {
            Object stream = data.getExtras().get(Intent.EXTRA_STREAM);
            if (stream instanceof Uri) {
                uri = (Uri) stream;
            }
        }
        if (uri == null) {
            emitError("gallery returned no image");
            return;
        }
        try {
            Activity activity = getActivity();
            if (activity != null) {
                activity.getContentResolver().takePersistableUriPermission(
                        uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
            }
        } catch (Exception ignored) {
        }
        copyAndEmit(uri);
    }

    private void copyAndEmit(@NonNull Uri uri) {
        Activity activity = getActivity();
        if (activity == null) {
            emitError("no activity");
            return;
        }
        File dest = new File(cacheImportsDir(activity), "import_" + System.currentTimeMillis() + ".jpg");
        Bitmap bmp = decodeScaled(activity, uri);
        if (bmp != null) {
            try (FileOutputStream out = new FileOutputStream(dest)) {
                bmp.compress(Bitmap.CompressFormat.JPEG, 92, out);
            } catch (Exception e) {
                bmp.recycle();
                Log.e(TAG, "compress jpeg", e);
                emitError(e.getMessage() == null ? "copy failed" : e.getMessage());
                return;
            }
            bmp.recycle();
            if (dest.exists() && dest.length() >= 32) {
                Log.i(TAG, "gallery jpeg " + dest.getAbsolutePath() + " bytes=" + dest.length());
                emitPath(dest.getAbsolutePath());
                return;
            }
        }
        try {
            try (InputStream in = activity.getContentResolver().openInputStream(uri);
                    OutputStream out = new FileOutputStream(dest)) {
                if (in == null) {
                    emitError("cannot open selected image");
                    return;
                }
                byte[] buf = new byte[8192];
                int n;
                while ((n = in.read(buf)) > 0) {
                    out.write(buf, 0, n);
                }
            }
            if (!dest.exists() || dest.length() < 32) {
                emitError("copied image is empty");
                return;
            }
            Log.i(TAG, "gallery copied " + dest.getAbsolutePath() + " bytes=" + dest.length());
            emitPath(dest.getAbsolutePath());
        } catch (Exception e) {
            Log.e(TAG, "copy uri", e);
            emitError(e.getMessage() == null ? "copy failed" : e.getMessage());
        }
    }

    @Nullable
    private static Bitmap decodeScaled(@NonNull Activity activity, @NonNull Uri uri) {
        BitmapFactory.Options bounds = new BitmapFactory.Options();
        bounds.inJustDecodeBounds = true;
        try (InputStream in = activity.getContentResolver().openInputStream(uri)) {
            if (in == null) {
                return null;
            }
            BitmapFactory.decodeStream(in, null, bounds);
        } catch (Exception e) {
            Log.w(TAG, "bounds", e);
            return null;
        }
        int maxDim = Math.max(bounds.outWidth, bounds.outHeight);
        if (maxDim <= 0) {
            return null;
        }
        int sample = 1;
        while (maxDim / sample > 4096) {
            sample *= 2;
        }
        BitmapFactory.Options opts = new BitmapFactory.Options();
        opts.inSampleSize = Math.max(sample, 1);
        try (InputStream in = activity.getContentResolver().openInputStream(uri)) {
            if (in == null) {
                return null;
            }
            return BitmapFactory.decodeStream(in, null, opts);
        } catch (Exception e) {
            Log.w(TAG, "decode", e);
            return null;
        }
    }

    private void saveBitmapAndEmit(@NonNull Bitmap bitmap) {
        Activity activity = getActivity();
        if (activity == null) {
            emitError("no activity");
            return;
        }
        try {
            File dest = new File(cacheImportsDir(activity), "capture_" + System.currentTimeMillis() + ".jpg");
            try (FileOutputStream out = new FileOutputStream(dest)) {
                bitmap.compress(Bitmap.CompressFormat.JPEG, 92, out);
            }
            emitPath(dest.getAbsolutePath());
        } catch (Exception e) {
            Log.e(TAG, "save bitmap", e);
            emitError(e.getMessage() == null ? "save failed" : e.getMessage());
        }
    }

    @NonNull
    private static File cameraOutputDir(@NonNull Activity activity) {
        File ext = activity.getExternalFilesDir(Environment.DIRECTORY_PICTURES);
        if (ext != null) {
            File dir = new File(ext, "imports");
            if (dir.exists() || dir.mkdirs()) {
                return dir;
            }
        }
        File files = activity.getFilesDir();
        File dir = new File(files, "imports");
        if (!dir.exists()) {
            dir.mkdirs();
        }
        return dir;
    }

    @NonNull
    private static File cacheImportsDir(@NonNull Activity activity) {
        File root = activity.getCacheDir();
        if (root == null) {
            root = activity.getFilesDir();
        }
        File dir = new File(root, "imports");
        if (!dir.exists()) {
            dir.mkdirs();
        }
        return dir;
    }

    private void emitPath(@NonNull String path) {
        runOnRenderThread(() -> emitSignal("image_picked", path));
    }

    private void emitError(@NonNull String message) {
        runOnRenderThread(() -> emitSignal("pick_error", message));
    }

    private void emitSignalOnRender(@NonNull String name) {
        runOnRenderThread(() -> emitSignal(name));
    }

    private void emitSignalOnRender(@NonNull String name, @NonNull String value) {
        runOnRenderThread(() -> emitSignal(name, value));
    }
}
