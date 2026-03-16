import java.util.Properties
import java.nio.charset.StandardCharsets

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

/**
 * CUSTOM BUILD ROUTING:
 * To avoid "Path too long" or "Different Drive Root" errors on Windows (Drive E:), 
 * we route the build outputs to a clean folder.
 */
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(StandardCharsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode: String = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName: String = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.curamind"
    
    // Using API 35 for the most modern Android 15 support
    compileSdk = 35 
    ndkVersion = "27.0.12077973"

    compileOptions {
        // --- CORE LIBRARY DESUGARING ---
        // Mandatory for 'health' plugin to handle Java 8+ Date/Time APIs on older devices
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.curamind"
        
        // Required for 'health' and 'flutter_local_notifications' (Min 26 for OREO)
        minSdk = 26 
        targetSdk = 35
        
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        
        // Enable MultiDex to handle large AI/ML dependency graphs
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            
            // Keeping these false during testing to avoid R8/ProGuard obfuscation issues
            isMinifyEnabled = false
            isShrinkResources = false 
        }
        
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Standard Kotlin library
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")

    // Mandatory dependency for the compileOptions.isCoreLibraryDesugaringEnabled flag
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

// --- RE-INITIATE REPOSITORIES ---
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}