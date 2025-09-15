# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core (누락된 클래스들)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Pigeon (Flutter 네이티브 통신)
-keep class io.flutter.plugins.** { *; }
-keep class dev.flutter.pigeon.** { *; }

# SharedPreferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Local Notifications
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Camera
-keep class io.flutter.plugins.camera.** { *; }

# Android Alarm Manager
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }

# FCM
-keep class io.flutter.plugins.firebase.messaging.** { *; }

# Cloud Firestore
-keep class io.flutter.plugins.firebase.firestore.** { *; }

# Firebase Auth
-keep class io.flutter.plugins.firebase.auth.** { *; }

# Firebase Core
-keep class io.flutter.plugins.firebase.core.** { *; }

# Firebase Storage
-keep class io.flutter.plugins.firebase.storage.** { *; }

# Gson (JSON 직렬화)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# 누락된 클래스들에 대한 경고 무시
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# 앱 모델 클래스 보호 (필요시 추가)
-keep class com.example.finalproject.** { *; }