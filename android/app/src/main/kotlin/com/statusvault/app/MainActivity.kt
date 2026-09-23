package com.statusvault.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "statusvault/storage"
    private var pendingFolderResult: MethodChannel.Result? = null
    private val folderRequestCode = 7011
    private val whatsappFolderRequestCode = 7012
    private var pendingWhatsAppResult: MethodChannel.Result? = null
    private var pendingWhatsAppType = "messenger"
    private val ioExecutor = Executors.newSingleThreadExecutor()

    override fun onDestroy() {
        ioExecutor.shutdownNow()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickStatusFolder" -> pickFolder(result)
                "scanStatusFolder" -> result.success(scanFolder())
                "scanWhatsAppStatus" -> {
                    val type = call.argument<String>("type") ?: "messenger"
                    ioExecutor.execute {
                        val items = try {
                            scanWhatsAppStatus(type)
                        } catch (_: Throwable) {
                            emptyList<Map<String, Any>>()
                        }
                        Handler(Looper.getMainLooper()).post {
                            result.success(items)
                        }
                    }
                }
                "isAllFilesAccessGranted" -> {
                    result.success(
                        android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.R ||
                            Environment.isExternalStorageManager()
                    )
                }
                "openAllFilesAccessSettings" -> {
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                            startActivity(Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                                data = Uri.parse("package:$packageName")
                            })
                        }
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                "pickWhatsAppStatusFolder" -> {
                    val type = call.argument<String>("type") ?: "messenger"
                    pickWhatsAppStatusFolder(type, result)
                }
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

    private fun pickWhatsAppStatusFolder(type: String, result: MethodChannel.Result) {
        pendingWhatsAppResult = result
        pendingWhatsAppType = type
        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }, whatsappFolderRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == whatsappFolderRequestCode) {
            val result = pendingWhatsAppResult ?: return
            pendingWhatsAppResult = null
            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                result.success(false)
                return
            }
            val uri = data.data!!
            try {
                contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                getPreferences(MODE_PRIVATE).edit()
                    .putString("whatsapp_status_tree_uri_$pendingWhatsAppType", uri.toString())
                    .apply()
                result.success(true)
            } catch (_: Exception) {
                result.success(false)
            }
            return
        }

        if (requestCode != folderRequestCode) return
        val result = pendingFolderResult ?: return
        pendingFolderResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(false)
            return
        }
        val uri = data.data!!
        try {
            contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            getPreferences(MODE_PRIVATE).edit().putString("status_tree_uri", uri.toString()).apply()
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun scanFolder(): List<Map<String, Any>> {
        val raw = getPreferences(MODE_PRIVATE).getString("status_tree_uri", null) ?: return emptyList()
        val root = DocumentFile.fromTreeUri(this, Uri.parse(raw)) ?: return emptyList()
        val output = mutableListOf<Map<String, Any>>()
        scan(root, output)
        return output
    }

    private fun scanSavedWhatsAppTree(type: String): List<Map<String, Any>> {
        val raw = getPreferences(MODE_PRIVATE).getString("whatsapp_status_tree_uri_$type", null) ?: return emptyList()
        val root = DocumentFile.fromTreeUri(this, Uri.parse(raw)) ?: return emptyList()
        val output = mutableListOf<Map<String, Any>>()
        scanWhatsAppTree(root, output)
        return output
    }

    private fun scanWhatsAppTree(dir: DocumentFile, output: MutableList<Map<String, Any>>) {
        for (f in dir.listFiles()) {
            if (f.isDirectory) {
                if (f.name == ".Statuses") {
                    scan(f, output)
                } else {
                    scanWhatsAppTree(f, output)
                }
            }
        }
    }

    private fun scanWhatsAppStatus(type: String): List<Map<String, Any>> {
        // Filesystem access under /Android/media can block; this method is always called on the IO executor.
        val output = mutableListOf<Map<String, Any>>()
        val relativeRoots = if (type == "business") {
            listOf(
                "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses",
                "WhatsApp Business/Media/.Statuses"
            )
        } else {
            listOf(
                "Android/media/com.whatsapp/WhatsApp/Media/.Statuses",
                "WhatsApp/Media/.Statuses"
            )
        }
        for (relative in relativeRoots) {
            val root = File("/storage/emulated/0", relative)
            if (root.isDirectory) {
                scanNativeDirectory(root, output)
                if (output.isNotEmpty()) break
            }
        }
        if (output.isEmpty()) output.addAll(scanSavedWhatsAppTree(type))
        return output.sortedByDescending { (it["modified"] as Long) }
    }

    private fun scanNativeDirectory(dir: File, output: MutableList<Map<String, Any>>) {
        val files = try { dir.listFiles() ?: return } catch (_: SecurityException) { return }
        for (file in files) {
            if (file.isDirectory) {
                scanNativeDirectory(file, output)
                continue
            }
            if (!file.isFile || !file.canRead()) continue
            val lower = file.name.lowercase()
            val isVideo = lower.endsWith(".mp4") || lower.endsWith(".3gp") ||
                lower.endsWith(".webm") || lower.endsWith(".mkv") || lower.endsWith(".mov")
            val isImage = lower.endsWith(".jpg") || lower.endsWith(".jpeg") ||
                lower.endsWith(".png") || lower.endsWith(".webp") || lower.endsWith(".gif") ||
                lower.endsWith(".heic") || lower.endsWith(".heif")
            if (!isImage && !isVideo) continue
            try {
                val outExt = file.extension.lowercase().let { if (it.isBlank()) "" else ".$it" }
                val cached = File(cacheDir, "statusvault_" + file.absolutePath.hashCode() + outExt)
                if (!cached.exists() || cached.length() != file.length()) {
                    FileOutputStream(cached).use { outputStream ->
                        file.inputStream().use { input -> input.copyTo(outputStream) }
                    }
                }
                output.add(mapOf(
                    "path" to cached.absolutePath,
                    "name" to file.name,
                    "mime" to mimeFor(file),
                    "isVideo" to isVideo,
                    "modified" to file.lastModified(),
                    "size" to file.length()
                ))
            } catch (_: Exception) { }
        }
    }

    private fun mimeFor(file: File): String {
        return when (file.extension.lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "webp" -> "image/webp"
            "gif" -> "image/gif"
            "heic" -> "image/heic"
            "heif" -> "image/heif"
            "mp4" -> "video/mp4"
            "3gp" -> "video/3gpp"
            "webm" -> "video/webm"
            "mkv" -> "video/x-matroska"
            "mov" -> "video/quicktime"
            else -> "application/octet-stream"
        }
    }

    private fun scan(dir: DocumentFile, output: MutableList<Map<String, Any>>) {
        for (f in dir.listFiles()) {
            if (f.isDirectory) {
                scan(f, output)
                continue
            }
            val mime = f.type ?: continue
            if (!mime.startsWith("image/") && !mime.startsWith("video/")) continue
            try {
                val ext = when {
                    mime.contains("jpeg") -> ".jpg"
                    mime.contains("png") -> ".png"
                    mime.contains("webp") -> ".webp"
                    mime.contains("mp4") -> ".mp4"
                    mime.contains("3gp") -> ".3gp"
                    else -> ""
                }
                val safe = (f.name ?: "status").replace(Regex("[^A-Za-z0-9._-]"), "_")
                val out = File(cacheDir, "statusvault_" + f.uri.toString().hashCode() + ext)
                if (!out.exists() || out.length() == 0L) {
                    contentResolver.openInputStream(f.uri)?.use { input ->
                        FileOutputStream(out).use { outputStream -> input.copyTo(outputStream) }
                    }
                }
                output.add(mapOf(
                    "path" to out.absolutePath,
                    "name" to (f.name ?: safe),
                    "mime" to mime,
                    "modified" to f.lastModified(),
                    "size" to out.length()
                ))
            } catch (_: Exception) { }
        }
    }

    private fun saveMedia(file: File, title: String): Boolean {
        if (!file.exists()) return false
        return try {
            val isVideo = file.extension.lowercase() in setOf("mp4", "3gp", "webm", "mkv", "mov")
            val collection = if (isVideo) MediaStore.Video.Media.EXTERNAL_CONTENT_URI else MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val mime = mimeFor(file)
            val values = android.content.ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, title.ifBlank { file.name })
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.MediaColumns.RELATIVE_PATH, if (isVideo) "Pictures/StatusVault/Videos" else "Pictures/StatusVault/Images")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(collection, values) ?: return false
            contentResolver.openOutputStream(uri)?.use { out -> file.inputStream().use { it.copyTo(out) } }
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            true
        } catch (_: Exception) { false }
    }
}
