import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;

class AppInfo {
  static PackageInfo? _packageInfo;

  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  static String get version {
    return _packageInfo?.version ?? 'Unknown';
  }
  
  static String get buildNumber {
    return _packageInfo?.buildNumber ?? '';
  }
  
  static String get versionWithBuild {
    final build = buildNumber.isNotEmpty ? ' ($buildNumber)' : '';
    return '$version$build';
  }
  
  // New methods for platform and ABI info
  static String get platformName {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isFuchsia) return 'Fuchsia';
    return 'Unknown';
  }
  
  static String get architecture {
    // Extract architecture from Platform.version string
    // Typically found at the end as "android_arm64" or similar
    final regex = RegExp(r'on\s+"([^"]+)"');
    final match = regex.firstMatch(Platform.version);
    return match?.group(1) ?? 'Unknown';
  }
  
  static String get androidVersion {
    try {
      // Extract just the Android OS version
      return Platform.operatingSystem == 'android' 
          ? Platform.operatingSystemVersion.split(' ')[0] 
          : '';
    } catch (e) {
      return '';
    }
  }
  
  static String get abiInfo {
    final version = androidVersion.isNotEmpty ? androidVersion : platformName;
    return '$version ($architecture)';
  }
}
