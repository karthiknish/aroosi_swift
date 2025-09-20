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
        applicationId = "com.aroosi.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 4
        versionName = "1.0.3"
    }

    signingConfigs {
        create("release") {
            // You can define signing config here or in a separate config file
            // For CI/CD, these values should be provided via environment variables
            val keystorePath = System.getenv("ANDROID_SIGNING_KEYSTORE_PATH") ?: "upload-keystore.jks"
            val keystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: ""
            val keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: ""
            val keyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: ""

            if (keystorePassword.isNotEmpty() && keyAlias.isNotEmpty() && keyPassword.isNotEmpty()) {
                storeFile = file(keystorePath)
                storePassword = keystorePassword
                keyAlias = keyAlias
                keyPassword = keyPassword
            } else {
                // Fallback to debug signing for local development
                initWith(signingConfigs.getByName("debug"))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
