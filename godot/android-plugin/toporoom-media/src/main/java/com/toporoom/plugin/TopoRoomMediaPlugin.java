package com.toporoom.plugin;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
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
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Wraps ACTION_IMAGE_CAPTURE and the system photo picker / GET_CONTENT so Godot
 * can receive a filesystem path after the user takes or picks a floor-plan photo.
 */
public class TopoRoomMediaPlugin extends GodotPlugin {
    private static final String TAG = "TopoRoomMedia";
    private static final String PLUGIN_NAME = "TopoRoomMedia";
    private static final int REQ_CAMERA = 4101;
    private static final int REQ_GALLERY = 4102;
    private static final int REQ_CAMERA_PERM = 4103;

    private static final SignalInfo IMAGE_PICKED = new SignalInfo("image_picked", String.class);
    private static final SignalInfo PICK_CANCELLED = new SignalInfo("pick_cancelled");
    private static final SignalInfo PICK_ERROR = new SignalInfo("pick_error", String.class);

    @Nullable private File pendingPhoto;

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
        return new HashSet<>(Arrays.asList(IMAGE_PICKED, PICK_CANCELLED, PICK_ERROR));
    }

    @NonNull
    @Override
    public List<String> getPluginMethods() {
        return Arrays.asList("capture_photo", "pick_gallery");
    }

    @UsedByGodot
    public void capture_photo() {
        runOnUiThread(this::launchCamera);
    }

    @UsedByGodot
    public void pick_gallery() {
        runOnUiThread(this::launchGallery);
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
            File dir = importsDir(activity);
            if (!dir.exists() && !dir.mkdirs()) {
                emitError("cannot create imports dir");
                return;
            }
            pendingPhoto = new File(dir, "capture_" + System.currentTimeMillis() + ".jpg");
            Uri uri = FileProvider.getUriForFile(
                    activity, activity.getPackageName() + ".fileprovider", pendingPhoto);
            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            intent.putExtra(MediaStore.EXTRA_OUTPUT, uri);
            intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION | Intent.FLAG_GRANT_READ_URI_PERMISSION);
            List<ResolveInfo> cameras = activity.getPackageManager()
                    .queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);
            for (ResolveInfo info : cameras) {
                activity.grantUriPermission(
                        info.activityInfo.packageName,
                        uri,
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION | Intent.FLAG_GRANT_READ_URI_PERMISSION);
            }
            if (cameras.isEmpty()) {
                emitError("no camera app");
                return;
            }
            activity.startActivityForResult(intent, REQ_CAMERA);
        } catch (ActivityNotFoundException e) {
            emitError("no camera app");
        } catch (Exception e) {
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
        try {
            Intent intent;
            if (Build.VERSION.SDK_INT >= 33) {
                intent = new Intent(MediaStore.ACTION_PICK_IMAGES);
            } else if (Build.VERSION.SDK_INT >= 19) {
                intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType("image/*");
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            } else {
                intent = new Intent(Intent.ACTION_GET_CONTENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
                intent.setType("image/*");
            }
            activity.startActivityForResult(intent, REQ_GALLERY);
        } catch (ActivityNotFoundException first) {
            try {
                Intent fallback = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
                fallback.setType("image/*");
                activity.startActivityForResult(Intent.createChooser(fallback, "选择户型图"), REQ_GALLERY);
            } catch (ActivityNotFoundException second) {
                emitError("no gallery");
            }
        } catch (Exception e) {
            Log.e(TAG, "pick_gallery", e);
            emitError(e.getMessage() == null ? "gallery failed" : e.getMessage());
        }
    }

    @Override
    public void onMainRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode != REQ_CAMERA_PERM) {
            return;
        }
        if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            launchCamera();
        } else {
            emitError("需要相机权限才能拍照");
        }
    }

    @Override
    public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != REQ_CAMERA && requestCode != REQ_GALLERY) {
            return;
        }
        if (resultCode != Activity.RESULT_OK) {
            pendingPhoto = null;
            emitSignalOnRender("pick_cancelled");
            return;
        }
        if (requestCode == REQ_CAMERA) {
            handleCameraResult(data);
            return;
        }
        handleGalleryResult(data);
    }

    private void handleCameraResult(@Nullable Intent data) {
        if (pendingPhoto != null && pendingPhoto.exists() && pendingPhoto.length() > 0) {
            String path = pendingPhoto.getAbsolutePath();
            pendingPhoto = null;
            emitPath(path);
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

    private void handleGalleryResult(@Nullable Intent data) {
        if (data == null) {
            emitError("gallery returned no image");
            return;
        }
        Uri uri = data.getData();
        if (uri == null && data.getClipData() != null && data.getClipData().getItemCount() > 0) {
            uri = data.getClipData().getItemAt(0).getUri();
        }
        if (uri == null) {
            emitError("gallery returned no image");
            return;
        }
        copyAndEmit(uri);
    }

    private void copyAndEmit(@NonNull Uri uri) {
        Activity activity = getActivity();
        if (activity == null) {
            emitError("no activity");
            return;
        }
        try {
            try (InputStream probe = activity.getContentResolver().openInputStream(uri)) {
                if (probe != null) {
                    Bitmap bmp = BitmapFactory.decodeStream(probe);
                    if (bmp != null) {
                        saveBitmapAndEmit(bmp);
                        return;
                    }
                }
            }
            File dest = new File(importsDir(activity), "import_" + System.currentTimeMillis() + ".jpg");
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
            emitPath(dest.getAbsolutePath());
        } catch (Exception e) {
            Log.e(TAG, "copy uri", e);
            emitError(e.getMessage() == null ? "copy failed" : e.getMessage());
        }
    }

    private void saveBitmapAndEmit(@NonNull Bitmap bitmap) {
        Activity activity = getActivity();
        if (activity == null) {
            emitError("no activity");
            return;
        }
        try {
            File dest = new File(importsDir(activity), "capture_" + System.currentTimeMillis() + ".jpg");
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
    private static File importsDir(@NonNull Activity activity) {
        File ext = activity.getExternalFilesDir(Environment.DIRECTORY_PICTURES);
        if (ext != null) {
            return new File(ext, "imports");
        }
        return new File(activity.getFilesDir(), "imports");
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
}
