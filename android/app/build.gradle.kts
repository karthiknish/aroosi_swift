plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google services for Firebase (required if using google-services.json)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.aroosi.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
    applicationId = "com.aroosi.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Ensure Google Maven repo is available via settings.gradle.kts (already there).

flutter {
    source = "../.."
}

// If using Firebase SDKs, include BOM here (optional; no-op if unused in Dart)
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    // Example dependencies (safe to leave, not used unless plugins added):
    // implementation("com.google.firebase:firebase-analytics")
}
