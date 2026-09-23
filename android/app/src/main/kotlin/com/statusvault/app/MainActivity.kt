package com.statusvault.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "statusvault/storage"
    private var pendingFolderResult: MethodChannel.Result? = null
    private val folderRequestCode = 7011

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickStatusFolder" -> pickFolder(result)
                "scanStatusFolder" -> result.success(scanFolder())
                "saveMedia" -> {
                    val path = call.argument<String>("path")
                    val title = call.argument<String>("title") ?: "StatusVault"
                    result.success(path?.let { saveMedia(File(it), title) })
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {
        pendingFolderResult = result
        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }, folderRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != folderRequestCode) return
        val result = pendingFolderResult ?: return
        pendingFolderResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) { result.success(false); return }
        val uri = data.data!!
        try {
            contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            getPreferences(MODE_PRIVATE).edit().putString("status_tree_uri", uri.toString()).apply()
            result.success(true)
        } catch (_: Exception) { result.success(false) }
    }

    private fun scanFolder(): List<Map<String, Any>> {
        val raw = getPreferences(MODE_PRIVATE).getString("status_tree_uri", null) ?: return emptyList()
        val root = DocumentFile.fromTreeUri(this, Uri.parse(raw)) ?: return emptyList()
        val output = mutableListOf<Map<String, Any>>()
        scan(root, output)
        return output
    }

    private fun scan(dir: DocumentFile, output: MutableList<Map<String, Any>>) {
        for (f in dir.listFiles()) {
            if (f.isDirectory) { scan(f, output); continue }
            val mime = f.type ?: continue
            if (!mime.startsWith("image/") && !mime.startsWith("video/")) continue
            try {
                val ext = when { mime.contains("jpeg") -> ".jpg"; mime.contains("png") -> ".png"; mime.contains("webp") -> ".webp"; mime.contains("mp4") -> ".mp4"; mime.contains("3gp") -> ".3gp"; else -> "" }
                val safe = (f.name ?: "status") .replace(Regex("[^A-Za-z0-9._-]"), "_")
                val out = File(cacheDir, "statusvault_${f.uri.toString().hashCode().toString()}$ext")
                if (!out.exists() || out.length() == 0L) contentResolver.openInputStream(f.uri)?.use { input -> FileOutputStream(out).use { outputStream -> input.copyTo(outputStream) } }
                output.add(mapOf("path" to out.absolutePath, "name" to (f.name ?: safe), "mime" to mime, "modified" to f.lastModified()))
            } catch (_: Exception) { }
        }
    }

    private fun saveMedia(file: File, title: String): Boolean {
        if (!file.exists()) return false
        return try {
            val isVideo = file.extension.lowercase() in setOf("mp4", "3gp", "webm", "mkv", "mov")
            val collection = if (isVideo) MediaStore.Video.Media.EXTERNAL_CONTENT_URI else MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val values = android.content.ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, title.ifBlank { file.name })
                put(MediaStore.MediaColumns.MIME_TYPE, if (isVideo) "video/mp4" else "image/jpeg")
                put(MediaStore.MediaColumns.RELATIVE_PATH, if (isVideo) "Pictures/StatusVault/Videos" else "Pictures/StatusVault/Images")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(collection, values) ?: return false
            contentResolver.openOutputStream(uri)?.use { out -> file.inputStream().use { it.copyTo(out) } }
            values.clear(); values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            true
        } catch (_: Exception) { false }
    }
}
