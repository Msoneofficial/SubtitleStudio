import 'dart:io';
import 'package:flutter/services.dart';

class MacOSBookmarkManager {
  static const MethodChannel _channel = MethodChannel('com.msone.subeditor/bookmark');

  static Future<Uint8List?> createBookmark(String filePath) async {
    if (!Platform.isMacOS) return null;
    try {
      final Uint8List? bookmark = await _channel.invokeMethod('createBookmark', {'filePath': filePath});
      return bookmark;
    } on PlatformException catch (e) {
      print("Failed to create bookmark: '${e.message}'.");
      return null;
    }
  }

  static Future<String?> resolveBookmark(Uint8List bookmark) async {
    if (!Platform.isMacOS) return null;
    try {
      final String? filePath = await _channel.invokeMethod('resolveBookmark', {'bookmark': bookmark});
      return filePath;
    } on PlatformException catch (e) {
      print("Failed to resolve bookmark: '${e.message}'.");
      return null;
    }
  }

  static Future<void> stopAccessingSecurityScopedResource(String filePath) async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('stopAccessingSecurityScopedResource', {'filePath': filePath});
    } on PlatformException catch (e) {
      print("Failed to stop accessing security-scoped resource: '${e.message}'.");
    }
  }
}
