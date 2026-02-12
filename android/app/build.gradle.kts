plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.edtech_offline_app"
    compileSdk = 36 // Latest SDK 16 (Android 16)
    
    // ✅ Specific NDK version for Gemma C++ performance
    ndkVersion = "28.2.13676358"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = "1.8"
    }
    
    defaultConfig {
        applicationId = "com.example.edtech_offline_app"
        // ✅ API 24 (Android 7) is the stable minimum for on-device LLMs
        minSdk = 24 
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            
            // ✅ IMPORTANT: Keep false to prevent R8 from stripping flutter_gemma binaries
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}