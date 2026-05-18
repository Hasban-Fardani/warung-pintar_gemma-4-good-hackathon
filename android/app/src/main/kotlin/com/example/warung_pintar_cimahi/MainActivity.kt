package com.example.warung_pintar_cimahi

import android.content.ContentResolver
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

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
                        result.success(uri)
                    } else {
                        result.success(null)
                    }
                }
                "copyFileFromMediaStore" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val destinationPath = call.argument<String>("destinationPath")
                    if (sourcePath == null || destinationPath == null) {
                        result.error("INVALID_ARGUMENT", "sourcePath and destinationPath are required", null)
                        return@setMethodCallHandler
                    }
                    val success = copyFile(sourcePath, destinationPath)
                    result.success(success)
                }
                "getFileSize" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_ARGUMENT", "path is required", null)
                        return@setMethodCallHandler
                    }
                    val size = getFileSize(path)
                    result.success(size)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun findFileInDownloads(fileName: String): String? {
        // Check if file exists at Downloads path directly
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val file = File(downloadsDir, fileName)
        
        if (file.exists() && file.length() > 100 * 1024 * 1024) {
            // Return the absolute path - we'll read it directly via method channel
            return file.absolutePath
        }
        
        return null
    }

    private fun copyFile(sourcePath: String, destinationPath: String): Boolean {
        return try {
            val sourceFile = File(sourcePath)
            val destFile = File(destinationPath)
            
            if (!sourceFile.exists()) {
                return false
            }
            
            FileInputStream(sourceFile).use { input ->
                destFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun getFileSize(path: String): Long {
        return try {
            File(path).length()
        } catch (e: Exception) {
            -1
        }
    }
}
