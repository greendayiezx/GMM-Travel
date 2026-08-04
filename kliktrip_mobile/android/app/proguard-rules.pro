# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep model classes used for JSON serialization
-keep class com.example.kliktrip_mobile.** { *; }

# Keep Dio & Retrofit
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep Flutter engine
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin
