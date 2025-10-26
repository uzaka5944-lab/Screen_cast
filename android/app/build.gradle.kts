plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.screen_cast" // Use your actual namespace here if different

    // --- [FIX 1] Set compileSdk to 36 ---
    compileSdk = 36

    // --- [FIX 2] Set the NDK version directly ---
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.screen_cast" // Use your actual application ID here if different

        // --- [FIX 3] Set minSdk to 29 ---
        minSdk = 29

        targetSdk = flutter.targetSdkVersion // Let Flutter manage targetSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Required for Desugaring
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Required for Desugaring
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}


flutter {
    source = "../.."
}