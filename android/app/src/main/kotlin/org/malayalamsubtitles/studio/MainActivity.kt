package org.malayalamsubtitles.studio

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "org.malayalamsubtitles.studio/intent"
    private val SAF_CHANNEL = "org.malayalamsubtitles.studio/saf"
    private var initialIntentData: String? = null
    
    // Request codes for SAF operations
    private val OPEN_DOCUMENT_REQUEST_CODE = 1001
    private val OPEN_DOCUMENT_URI_ONLY_REQUEST_CODE = 1003
    private val CREATE_DOCUMENT_REQUEST_CODE = 1004  // Changed from 1002 to avoid conflict with ffmpeg-kit
    
    // Pending method call results for SAF operations
    private var pendingSafResult: MethodChannel.Result? = null
    private var pendingSafContent: ByteArray? = null
    
    // Maximum file size to read into memory (10 MB)
    // Files larger than this should use openFileUriOnly or streaming
    private val MAX_READ_SIZE_BYTES = 10 * 1024 * 1024L  // 10 MB

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Handle initial intent
        handleIntent(intent)
        
        // Setup intent channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialIntentData" -> {
                    result.success(initialIntentData)
                    initialIntentData = null // Clear after sending
                }
                "readFileFromContentUri" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        try {
                            val parsedUri = Uri.parse(uri)
                            val fileSize = getFileSize(parsedUri)
                            
                            // If file is larger than MAX_READ_SIZE_BYTES, don't load into memory
                            if (fileSize > MAX_READ_SIZE_BYTES) {
                                result.error(
                                    "FILE_TOO_LARGE", 
                                    "File is too large to load into memory (${fileSize / (1024 * 1024)}MB). Use getFileDescriptorPath instead.", 
                                    null
                                )
                                return@setMethodCallHandler
                            }
                            
                            // File is small enough, read it with OutOfMemoryError protection
                            val content = readContentFromUri(parsedUri)
                            if (content != null) {
                                result.success(content)
                            } else {
                                result.error("READ_ERROR", "Failed to read file content", null)
                            }
                        } catch (e: OutOfMemoryError) {
                            Log.e("MainActivity", "OutOfMemoryError reading file from URI: $uri", e)
                            result.error("OUT_OF_MEMORY", "File is too large to load into memory. Use getFileDescriptorPath instead.", null)
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Error reading file from URI: $uri", e)
                            result.error("READ_ERROR", "Error reading file from URI: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI is null", null)
                    }
                }
                "getFileDescriptorPath" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        try {
                            val fileDescriptorPath = getFileDescriptorPath(Uri.parse(uri))
                            result.success(fileDescriptorPath)
                        } catch (e: Exception) {
                            result.error("FD_ERROR", "Error getting file descriptor path: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Setup SAF channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SAF_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFile" -> {
                    handleOpenFile(call, result)
                }
                "openFileUriOnly" -> {
                    handleOpenFileUriOnly(call, result)
                }
                "createDocument" -> {
                    handleCreateDocument(call, result)
                }
                "saveNewFile" -> {
                    handleSaveNewFile(call, result)
                }
                "saveExistingFile" -> {
                    handleSaveExistingFile(call, result)
                }
                "hasUriPermission" -> {
                    handleHasUriPermission(call, result)
                }
                "releaseUriPermission" -> {
                    handleReleaseUriPermission(call, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        Log.d("MainActivity", "onActivityResult: requestCode=$requestCode, resultCode=$resultCode, data=$data")
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            OPEN_DOCUMENT_REQUEST_CODE, OPEN_DOCUMENT_URI_ONLY_REQUEST_CODE -> {
                Log.d("MainActivity", "Handling OPEN_DOCUMENT request (URI-only mode)")
                handleOpenDocumentUriOnlyResult(resultCode, data)
            }
            CREATE_DOCUMENT_REQUEST_CODE -> {
                Log.d("MainActivity", "Handling CREATE_DOCUMENT_REQUEST_CODE")
                handleCreateDocumentResult(resultCode, data)
            }
            else -> {
                Log.d("MainActivity", "Unknown request code: $requestCode")
            }
        }
    }
    
    private fun handleOpenFile(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        // Redirect to URI-only mode to prevent OutOfMemoryError
        // This ensures all file picking operations are memory-safe
        handleOpenFileUriOnly(call, result)
    }
    
    private fun handleOpenFileUriOnly(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        try {
            val mimeTypes = call.argument<List<String>>("mimeTypes") ?: listOf("*/*")
            
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = if (mimeTypes.size == 1) mimeTypes[0] else "*/*"
                
                if (mimeTypes.size > 1) {
                    putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
                }
                
                // Request persistent permission to access the file
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            }
            
            pendingSafResult = result
            startActivityForResult(intent, OPEN_DOCUMENT_URI_ONLY_REQUEST_CODE)
            
        } catch (e: Exception) {
            result.error("OPEN_FILE_URI_ONLY_ERROR", "Failed to open file picker: ${e.message}", null)
        }
    }
    
    private fun handleCreateDocument(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        try {
            val fileName = call.argument<String>("fileName") ?: "untitled.txt"
            val mimeType = call.argument<String>("mimeType") ?: "text/plain"
            
            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = mimeType
                putExtra(Intent.EXTRA_TITLE, fileName)
                
                // Request persistent permission to access the file
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            }
            
            pendingSafResult = result
            startActivityForResult(intent, CREATE_DOCUMENT_REQUEST_CODE)
            
        } catch (e: Exception) {
            result.error("CREATE_DOCUMENT_ERROR", "Failed to open save dialog: ${e.message}", null)
        }
    }
    
    private fun handleSaveNewFile(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        try {
            val content = call.argument<ByteArray>("content")
            val fileName = call.argument<String>("fileName")
            val mimeType = call.argument<String>("mimeType") ?: "text/plain"
            
            if (content == null || fileName == null) {
                result.error("INVALID_ARGUMENT", "Content and fileName are required", null)
                return
            }
            
            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = mimeType
                putExtra(Intent.EXTRA_TITLE, fileName)
                
                // Request persistent permission to write to the file
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            }
            
            pendingSafResult = result
            pendingSafContent = content
            startActivityForResult(intent, CREATE_DOCUMENT_REQUEST_CODE)
            
        } catch (e: Exception) {
            result.error("SAVE_NEW_FILE_ERROR", "Failed to open save dialog: ${e.message}", null)
        }
    }
    
    private fun handleSaveExistingFile(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        try {
            val uriString = call.argument<String>("uri")
            val content = call.argument<ByteArray>("content")
            
            if (uriString == null || content == null) {
                result.error("INVALID_ARGUMENT", "URI and content are required", null)
                return
            }
            
            val uri = Uri.parse(uriString)
            val success = writeContentToUri(uri, content)
            result.success(success)
            
        } catch (e: Exception) {
            result.error("SAVE_EXISTING_FILE_ERROR", "Failed to save file: ${e.message}", null)
        }
    }
    
    
    private fun handleOpenDocumentUriOnlyResult(resultCode: Int, data: Intent?) {
        val result = pendingSafResult
        pendingSafResult = null
        
        if (result == null) return
        
        if (resultCode == Activity.RESULT_OK && data?.data != null) {
            try {
                val uri = data.data!!
                
                // Take persistent permission for future access across app sessions
                contentResolver.takePersistableUriPermission(
                    uri, 
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
                
                // Only get display path, don't read content for large files
                val displayPath = getDisplayPathFromUri(uri)
                
                if (displayPath != null) {
                    val resultMap = mapOf(
                        "uri" to uri.toString(),
                        "displayPath" to displayPath
                        // No content field - this is the key difference
                    )
                    result.success(resultMap)
                } else {
                    result.error("PATH_ERROR", "Failed to get display path", null)
                }
                
            } catch (e: Exception) {
                result.error("OPEN_DOCUMENT_URI_ONLY_ERROR", "Failed to process opened document: ${e.message}", null)
            }
        } else {
            result.success(null) // User cancelled
        }
    }
    
    private fun handleCreateDocumentResult(resultCode: Int, data: Intent?) {
        Log.d("MainActivity", "handleCreateDocumentResult: resultCode=$resultCode, data=$data")
        val result = pendingSafResult
        val content = pendingSafContent
        pendingSafResult = null
        pendingSafContent = null
        
        Log.d("MainActivity", "pendingResult=$result, contentSize=${content?.size}")
        
        if (result == null) {
            Log.e("MainActivity", "No pending result for CREATE_DOCUMENT")
            return
        }
        
        if (resultCode == Activity.RESULT_OK && data?.data != null) {
            try {
                val uri = data.data!!
                Log.d("MainActivity", "Document created with URI: $uri")
                
                // Take persistent permission
                contentResolver.takePersistableUriPermission(
                    uri, 
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
                
                val displayPath = getDisplayPathFromUri(uri)
                Log.d("MainActivity", "Display path: $displayPath")
                
                if (displayPath != null) {
                    // Check if we have content to write (saveNewFile case)
                    if (content != null) {
                        Log.d("MainActivity", "Writing content to document (saveNewFile case)")
                        val writeSuccess = writeContentToUri(uri, content)
                        if (writeSuccess) {
                            Log.d("MainActivity", "Content written successfully")
                            val resultMap = mapOf(
                                "uri" to uri.toString(),
                                "displayPath" to displayPath
                            )
                            result.success(resultMap)
                        } else {
                            Log.e("MainActivity", "Failed to write content to document")
                            result.error("WRITE_ERROR", "Failed to write content to file", null)
                        }
                    } else {
                        Log.d("MainActivity", "No content to write (createDocument case)")
                        // No content case (createDocument) - just return URI
                        val resultMap = mapOf(
                            "uri" to uri.toString(),
                            "displayPath" to displayPath
                        )
                        result.success(resultMap)
                    }
                } else {
                    Log.e("MainActivity", "Failed to get display path for URI: $uri")
                    result.error("DISPLAY_PATH_ERROR", "Failed to get display path for saved file", null)
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error in handleCreateDocumentResult", e)
                result.error("CREATE_DOCUMENT_ERROR", "Failed to process created document: ${e.message}", null)
            }
        } else {
            Log.d("MainActivity", "Create document cancelled or failed: resultCode=$resultCode")
            result.success(null) // User cancelled or error
        }
    }
    
    private fun readContentFromUri(uri: Uri): ByteArray? {
        return try {
            // Check file size first to prevent OutOfMemoryError
            val fileSize = getFileSize(uri)
            
            if (fileSize > MAX_READ_SIZE_BYTES) {
                Log.w("MainActivity", "File too large to read into memory: $fileSize bytes (max: $MAX_READ_SIZE_BYTES)")
                return null
            }
            
            contentResolver.openInputStream(uri)?.use { inputStream ->
                inputStream.readBytes()
            }
        } catch (e: IOException) {
            Log.e("MainActivity", "IOException reading content from URI", e)
            null
        } catch (e: OutOfMemoryError) {
            Log.e("MainActivity", "OutOfMemoryError reading content from URI", e)
            null
        }
    }
    
    private fun getFileSize(uri: Uri): Long {
        return try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) {
                        return cursor.getLong(sizeIndex)
                    }
                }
            }
            // If size cannot be determined, return max to fail safely
            MAX_READ_SIZE_BYTES + 1
        } catch (e: Exception) {
            Log.w("MainActivity", "Failed to get file size for URI: $uri", e)
            // Return max to fail safely
            MAX_READ_SIZE_BYTES + 1
        }
    }
    
    private fun writeContentToUri(uri: Uri, content: ByteArray): Boolean {
        return try {
            // Use "wt" mode (write/truncate) as recommended in Android File Storage Guide
            // This ensures we overwrite the existing file content completely
            contentResolver.openOutputStream(uri, "wt")?.use { outputStream ->
                outputStream.write(content)
                outputStream.flush() // Ensure content is written
            }
            true
        } catch (e: IOException) {
            // Debug logging removed for simplicity
            false
        } catch (e: SecurityException) {
            // Handle cases where URI permission might have been revoked
            // Debug logging removed for simplicity
            false
        }
    }
    
    private fun getDisplayPathFromUri(uri: Uri): String? {
        return try {
            // Use comprehensive approach from Android File Storage Guide
            getUriDisplayNameUsingContentResolver(uri) ?: extractFileNameFromUri(uri)
        } catch (e: Exception) {
            // Fallback to basic URI path extraction
            extractFileNameFromUri(uri)
        }
    }
    
    private fun getUriDisplayNameUsingContentResolver(uri: Uri): String? {
        // Query multiple columns for comprehensive file information
        val projection = arrayOf(
            OpenableColumns.DISPLAY_NAME,
            OpenableColumns.SIZE,
            "_data", // Some providers support this
            "title"  // Some providers use this
        )
        
        return try {
            contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    // Try DISPLAY_NAME first (most reliable)
                    val displayNameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (displayNameIndex >= 0) {
                        val displayName = cursor.getString(displayNameIndex)
                        if (!displayName.isNullOrBlank()) {
                            return buildDisplayPath(uri, displayName)
                        }
                    }
                    
                    // Fallback to _data column (full path on some providers)
                    val dataIndex = cursor.getColumnIndex("_data")
                    if (dataIndex >= 0) {
                        val fullPath = cursor.getString(dataIndex)
                        if (!fullPath.isNullOrBlank()) {
                            return fullPath
                        }
                    }
                    
                    // Fallback to title column
                    val titleIndex = cursor.getColumnIndex("title")
                    if (titleIndex >= 0) {
                        val title = cursor.getString(titleIndex)
                        if (!title.isNullOrBlank()) {
                            return buildDisplayPath(uri, title)
                        }
                    }
                }
                null
            }
        } catch (e: Exception) {
            null
        }
    }
    
    private fun buildDisplayPath(uri: Uri, fileName: String): String {
        // Build user-friendly display path based on content provider
        return when {
            uri.authority?.contains("com.android.externalstorage") == true -> {
                val path = uri.path
                if (path?.contains("/primary:") == true) {
                    val relativePath = path.substringAfter("/primary:")
                    val dirPath = relativePath.substringBeforeLast("/", "")
                    if (dirPath.isNotEmpty()) {
                        "/storage/emulated/0/$relativePath"
                    } else {
                        "/storage/emulated/0/$fileName"
                    }
                } else {
                    "External Storage/$fileName"
                }
            }
            uri.authority?.contains("com.android.providers.downloads") == true -> {
                "Downloads/$fileName"
            }
            uri.authority?.contains("com.android.providers.media") == true -> {
                val path = uri.path
                when {
                    path?.contains("/images/") == true -> "Pictures/$fileName"
                    path?.contains("/video/") == true -> "Movies/$fileName"
                    path?.contains("/audio/") == true -> "Music/$fileName"
                    else -> "Media/$fileName"
                }
            }
            else -> {
                // For other providers (Google Drive, Dropbox, etc.), just use filename
                fileName
            }
        }
    }
    
    private fun extractFileNameFromUri(uri: Uri): String? {
        // Fallback method for extracting filename from URI
        return try {
            when (uri.scheme) {
                "content" -> {
                    val path = uri.path
                    path?.substringAfterLast("/") ?: uri.lastPathSegment
                }
                "file" -> {
                    uri.lastPathSegment
                }
                else -> {
                    uri.toString().substringAfterLast("/")
                }
            }
        } catch (e: Exception) {
            "Unknown File"
        }
    }
    
    private fun getFileDescriptorPath(uri: Uri): String? {
        return try {
            Log.d("MainActivity", "Getting file descriptor path for URI: $uri")
            // Try to get a file descriptor that FFmpeg can use
            val pfd = contentResolver.openFileDescriptor(uri, "r")
            if (pfd != null) {
                val fd = pfd.fileDescriptor
                val fdInt = fd.javaClass.getDeclaredField("fd").apply { isAccessible = true }.getInt(fd)
                val fdPath = "/proc/self/fd/$fdInt"
                Log.d("MainActivity", "Generated file descriptor path: $fdPath")
                // Note: We don't close the file descriptor here as FFmpeg needs it
                // It will be closed when the process ends or GC occurs
                fdPath
            } else {
                Log.w("MainActivity", "Failed to open file descriptor for URI: $uri")
                null
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error getting file descriptor path for URI: $uri", e)
            null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val uri: Uri? = intent.data
            if (uri != null) {
                
                // Take persistent permission for content URIs to enable saving back later
                if (uri.scheme == "content") {
                    try {
                        contentResolver.takePersistableUriPermission(
                            uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        )
                        Log.d("MainActivity", "Took persistent permissions for intent URI: $uri")
                    } catch (e: Exception) {
                        Log.w("MainActivity", "Could not take persistent permission for intent URI: $uri", e)
                        // Continue anyway - app can still read the file, just might not be able to save back
                    }
                }
                
                val path = getPathFromUri(uri)
                if (path != null && (path.endsWith(".srt", ignoreCase = true) || path.endsWith(".msone", ignoreCase = true))) {
                    // Determine the action based on which activity alias was used
                    val componentName = intent.component?.className
                    val action = when (componentName) {
                        "org.malayalamsubtitles.studio.ImportActivity" -> "import"
                        "org.malayalamsubtitles.studio.SourceViewActivity" -> "source_view"
                        else -> "import" // Default to import for backwards compatibility
                    }
                    
                    // Create JSON with path and action
                    initialIntentData = """{"path":"$path","action":"$action"}"""
                }
            }
        } else if (intent?.action == Intent.ACTION_SEND) {
            val uri: Uri? = intent.getParcelableExtra(Intent.EXTRA_STREAM)
            if (uri != null) {
                
                // Take persistent permission for content URIs to enable saving back later
                if (uri.scheme == "content") {
                    try {
                        contentResolver.takePersistableUriPermission(
                            uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        )
                        Log.d("MainActivity", "Took persistent permissions for SEND intent URI: $uri")
                    } catch (e: Exception) {
                        Log.w("MainActivity", "Could not take persistent permission for SEND intent URI: $uri", e)
                        // Continue anyway - app can still read the file, just might not be able to save back
                    }
                }
                
                val path = getPathFromUri(uri)
                if (path != null && (path.endsWith(".srt", ignoreCase = true) || path.endsWith(".msone", ignoreCase = true))) {
                    // SEND actions always default to import
                    initialIntentData = """{"path":"$path","action":"import"}"""
                }
            }
        }
    }

    private fun getPathFromUri(uri: Uri): String? {
        return when (uri.scheme) {
            "file" -> uri.path
            "content" -> {
                try {
                    // For content URIs, always return the URI string for Flutter to handle
                    // We'll process the content in Flutter using the readFileFromContentUri method
                    val uriString = uri.toString()
                    
                    // Check if it's likely an SRT or MSONE file by examining the URI
                    if (uriString.contains(".srt", ignoreCase = true) || 
                        uriString.contains("srt", ignoreCase = true) ||
                        uriString.contains(".msone", ignoreCase = true) ||
                        uriString.contains("msone", ignoreCase = true)) {
                        return uriString
                    }
                    
                    // Also try to get display name for validation
                    val cursor = contentResolver.query(uri, null, null, null, null)
                    cursor?.use {
                        if (it.moveToFirst()) {
                            val displayNameIndex = it.getColumnIndex("_display_name")
                            if (displayNameIndex >= 0) {
                                val displayName = it.getString(displayNameIndex)
                                if (displayName != null && (displayName.endsWith(".srt", ignoreCase = true) || displayName.endsWith(".msone", ignoreCase = true))) {
                                    return uriString
                                }
                            }
                        }
                    }
                    
                    // If we reach here and still not sure, return the URI anyway
                    // The Flutter side will validate and handle appropriately
                    return uriString
                    
                } catch (e: Exception) {
                    // Return URI as string for Flutter to handle
                    return uri.toString()
                }
            }
            else -> {
                // For other schemes, check if it might be an SRT or MSONE file reference
                val uriString = uri.toString()
                if (uriString.contains(".srt", ignoreCase = true) || uriString.contains(".msone", ignoreCase = true)) {
                    uriString
                } else {
                    null
                }
            }
        }
    }

    private fun handleHasUriPermission(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        try {
            val uriString = call.argument<String>("uri")
            
            if (uriString == null) {
                result.error("INVALID_ARGUMENT", "URI is required", null)
                return
            }
            
            val uri = Uri.parse(uriString)
            
            // Check if we have persistent permission for this URI
            val hasPermission = try {
                contentResolver.persistedUriPermissions.any { permission ->
                    permission.uri == uri && (
                        permission.isReadPermission || permission.isWritePermission
                    )
                }
            } catch (e: Exception) {
                false
            }
            
            result.success(hasPermission)
            
        } catch (e: Exception) {
            result.error("HAS_URI_PERMISSION_ERROR", "Failed to check URI permission: ${e.message}", null)
        }
    }
    
    private fun handleReleaseUriPermission(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        try {
            val uriString = call.argument<String>("uri")
            
            if (uriString == null) {
                result.error("INVALID_ARGUMENT", "URI is required", null)
                return
            }
            
            val uri = Uri.parse(uriString)
            
            // Release persistent permission for this URI
            val success = try {
                contentResolver.releasePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
                true
            } catch (e: Exception) {
                // Debug logging removed for simplicity
                false
            }
            
            result.success(success)
            
        } catch (e: Exception) {
            result.error("RELEASE_URI_PERMISSION_ERROR", "Failed to release URI permission: ${e.message}", null)
        }
    }
}
