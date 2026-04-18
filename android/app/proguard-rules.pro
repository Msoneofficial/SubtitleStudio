##############################################
# Flutter & Plugin ProGuard Rules
##############################################

# --- Flutter core & embedding ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep GeneratedPluginRegistrant (important for plugin registration)
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

##############################################
# Pigeon (all plugins that use it)
##############################################
# Keep all classes & interfaces
-keep class dev.flutter.pigeon.** { *; }
-keep interface dev.flutter.pigeon.** { *; }

# Keep constructors & methods (for reflection)
-keepclassmembers class dev.flutter.pigeon.** {
    <init>(...);
    *;
}

##############################################
# Plugins
##############################################

# Google Play Core / in_app_update
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.**
-keep class dev.fluttercommunity.in_app_update.** { *; }

# Isar database
-keep class **.*_Collection { *; }
-keep class **.*_Schema { *; }
-keep @isar.annotation.* class *

# Media Kit
-keep class media_kit.** { *; }
-keep class com.alexmercerind.media_kit_video.** { *; }

# FFmpeg Kit - Comprehensive rules to prevent R8 conflicts
-keep class com.arthenica.** { *; }
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep interface com.antonkarpenko.ffmpegkit.** { *; }
-keep enum com.antonkarpenko.ffmpegkit.** { *; }

# Keep FFmpeg Kit native methods and JNI
-keepclasseswithmembernames class com.antonkarpenko.ffmpegkit.** {
    native <methods>;
}

# Keep FFmpeg Kit ABI detection
-keep class com.antonkarpenko.ffmpegkit.AbiDetect { *; }
-keepclassmembers class com.antonkarpenko.ffmpegkit.AbiDetect {
    public static <methods>;
    native <methods>;
}

# Keep FFmpeg Kit configuration
-keep class com.antonkarpenko.ffmpegkit.FFmpegKitConfig { *; }
-keepclassmembers class com.antonkarpenko.ffmpegkit.FFmpegKitConfig {
    public static <methods>;
    native <methods>;
}

# Keep all callback interfaces
-keep interface com.antonkarpenko.ffmpegkit.*Callback { *; }
-keep class * implements com.antonkarpenko.ffmpegkit.*Callback { *; }

# Keep session classes
-keep class com.antonkarpenko.ffmpegkit.*Session { *; }
-keep class com.antonkarpenko.ffmpegkit.MediaInformation { *; }
-keep class com.antonkarpenko.ffmpegkit.Chapter { *; }
-keep class com.antonkarpenko.ffmpegkit.StreamInformation { *; }

# Prevent obfuscation of FFmpeg Kit
-keep,allowobfuscation class com.antonkarpenko.ffmpegkit.**
-keepnames class com.antonkarpenko.ffmpegkit.**

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Package Info
-keep class io.flutter.plugins.packageinfo.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Device Info
-keep class io.flutter.plugins.deviceinfo.** { *; }

# Volume Controller
-keep class com.yung.volume_controller.** { *; }

# Screen Brightness
-keep class com.aaassseee.screen_brightness_android.** { *; }

# Wakelock
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }

##############################################
# General Java rules
##############################################

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes with native methods (especially important for FFmpeg)
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep classes loaded via JNI
-keep class * {
    public static <methods>;
}

# Keep native library loading (static initializers)
-keepclassmembers class * {
    <clinit>();
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
    @io.flutter.plugin.common.MethodChannel$MethodCallHandler <methods>;
}

##############################################
# Metadata & Debug Info
##############################################

# Keep annotations & generic signatures
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep line numbers for crash reporting
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

##############################################
# Optimizations
##############################################
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*,!code/allocation/variable
-allowaccessmodification
-dontpreverify
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses

##############################################
# Suppress warnings for platform-specific APIs
##############################################
-dontwarn java.lang.management.**
-dontwarn javax.management.**
-dontwarn org.slf4j.**
-dontwarn ch.qos.logback.**

# Uncomment to debug minification
 -verbose
