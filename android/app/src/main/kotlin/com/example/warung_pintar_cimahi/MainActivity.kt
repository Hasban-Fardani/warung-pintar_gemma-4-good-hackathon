package com.example.warung_pintar_cimahi

import android.content.ContentResolver
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "warung_pintar_cimahi/mediastore"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "findDownloadedFile" -> {
                    val fileName = call.argument<String>("fileName")
                    if (fileName == null) {
                        result.error("INVALID_ARGUMENT", "fileName is required", null)
                        return@setMethodCallHandler
                    }
                    val uri = findFileInDownloads(fileName)
                    if (uri != null) {
                        result.success(uri.toString())
                    } else {
                        result.success(null)
                    }
                }
                "copyFileFromMediaStore" -> {
                    val contentUri = call.argument<String>("contentUri")
                    val destinationPath = call.argument<String>("destinationPath")
                    if (contentUri == null || destinationPath == null) {
                        result.error("INVALID_ARGUMENT", "contentUri and destinationPath are required", null)
                        return@setMethodCallHandler
                    }
                    val success = copyFile(contentUri, destinationPath)
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun findFileInDownloads(fileName: String): Uri? {
        val contentResolver: ContentResolver = contentResolver

        // Try MediaStore.Downloads first (Android Q+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val projection = arrayOf(
                MediaStore.Downloads._ID,
                MediaStore.Downloads.DISPLAY_NAME,
                MediaStore.Downloads.SIZE
            )
            val selection = "${MediaStore.Downloads.DISPLAY_NAME} = ?"
            val selectionArgs = arrayOf(fileName)

            contentResolver.query(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
                    val id = cursor.getLong(idColumn)
                    return Uri.withAppendedPath(MediaStore.Downloads.EXTERNAL_CONTENT_URI, id.toString())
                }
            }
        }

        // Fallback for older Android - scan external storage
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val file = File(downloadsDir, fileName)
        if (file.exists() && file.length() > 100 * 1024 * 1024) {
            // For older Android, we need to get a content URI
            // Use FileProvider workaround - create a content URI from the file path
            return getContentUriFromFile(file)
        }

        return null
    }

    private fun getContentUriFromFile(file: File): Uri? {
        // Try to find existing content URI first
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val projection = arrayOf(MediaStore.Downloads._ID)
            val selection = "${MediaStore.Downloads.DISPLAY_NAME} = ? AND ${MediaStore.Downloads.SIZE} = ?"
            val selectionArgs = arrayOf(file.name, file.length().toString())

            contentResolver.query(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
                    val id = cursor.getLong(idColumn)
                    return Uri.withAppendedPath(MediaStore.Downloads.EXTERNAL_CONTENT_URI, id.toString())
                }
            }
        }

        // If not found in MediaStore but file exists, add it
        return addFileToMediaStore(file)
    }

    private fun addFileToMediaStore(file: File): Uri? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, file.name)
                put(MediaStore.Downloads.MIME_TYPE, "application/octet-stream")
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
            if (uri != null) {
                contentResolver.openOutputStream(uri)?.use { outputStream ->
                    file.inputStream().use { inputStream ->
                        inputStream.copyTo(outputStream)
                    }
                }

                contentValues.clear()
                contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                contentResolver.update(uri, contentValues, null, null)

                return uri
            }
        }
        return null
    }

    private fun copyFile(contentUriString: String, destinationPath: String): Boolean {
        return try {
            val contentUri = Uri.parse(contentUriString)
            val destinationFile = File(destinationPath)

            contentResolver.openInputStream(contentUri)?.use { inputStream: InputStream ->
                FileOutputStream(destinationFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            } ?: return false

            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
