# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# MediaPipe / Gemma (flutter_gemma)
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Javax Annotation Processing (from auto-value or other generators)
-dontwarn javax.annotation.processing.**
-dontwarn javax.lang.model.**
-keep class javax.annotation.processing.** { *; }
-keep class javax.lang.model.** { *; }

# Google Play Core (referenced by flutter)
-dontwarn com.google.android.play.core.**
