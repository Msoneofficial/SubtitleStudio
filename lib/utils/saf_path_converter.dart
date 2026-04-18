/// Utility class for converting SAF content URIs to proper display paths
/// 
/// This fixes the inconsistency where Android's native SAF implementation
/// sometimes omits intermediate folders in the display path conversion.
class SafPathConverter {
  
  /// Convert a SAF content URI to a proper display path
  /// 
  /// Example:
  /// Input: content://com.android.externalstorage.documents/document/primary%3ADownload%2F1DM%2F_file.srt
  /// Output: /storage/emulated/0/Download/1DM/_file.srt
  /// 
  /// [contentUri] - The SAF content URI to convert
  /// 
  /// Returns the proper display path with all folders preserved
  static String convertSafUriToDisplayPath(String contentUri) {
    try {
      // Only process external storage documents
      if (!contentUri.startsWith('content://com.android.externalstorage.documents/document/')) {
        // For other providers, return the URI as-is since we can't reliably convert them
        return contentUri;
      }
      
      // Extract the document ID from the URI
      final uri = Uri.parse(contentUri);
      final pathSegments = uri.pathSegments;
      
      // Look for the document segment
      if (pathSegments.length >= 2 && pathSegments[0] == 'document') {
        final documentId = pathSegments[1];
        
        // Decode the document ID
        final decodedDocId = Uri.decodeFull(documentId);
        
        // Check if it's a primary storage document
        if (decodedDocId.startsWith('primary:')) {
          // Remove the 'primary:' prefix
          final relativePath = decodedDocId.substring(8); // Remove 'primary:'
          
          // Convert to absolute path
          final absolutePath = '/storage/emulated/0/$relativePath';
          
          return absolutePath;
        } else {
          // For non-primary storage, try to construct a reasonable path
          // This handles SD cards and other external storage
          return '/storage/$decodedDocId';
        }
      }
      
      // If we can't parse it, return the original URI
      return contentUri;
    } catch (e) {
      // If any error occurs during parsing, return the original URI
      return contentUri;
    }
  }
  
  /// Check if the given path looks like a SAF content URI
  /// 
  /// [path] - The path or URI to check
  /// 
  /// Returns true if it's a SAF content URI
  static bool isContentUri(String path) {
    return path.startsWith('content://');
  }
  
  /// Normalize a path that might be either a regular file path or SAF URI
  /// 
  /// [pathOrUri] - The path or SAF URI to normalize
  /// 
  /// Returns the proper display path
  static String normalizePath(String pathOrUri) {
    if (isContentUri(pathOrUri)) {
      return convertSafUriToDisplayPath(pathOrUri);
    } else {
      return pathOrUri;
    }
  }
}