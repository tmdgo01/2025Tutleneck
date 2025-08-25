plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // ✅ 최신 표준 (kotlin-android 대신 org.jetbrains.kotlin.android)
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.finalproject"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // ✅ NDK 버전 고정

    defaultConfig {
        applicationId = "com.example.finalproject"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // ✅ flutter run --release 시 필요
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.23") // ✅ 안정된 최신 버전
}
