import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("app/key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "pro.moneyplan.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "pro.moneyplan.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // Signing configurations
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("KEYSTORE_FILE"))
                storePassword = keystoreProperties.getProperty("KEYSTORE_PASSWORD")
                keyAlias = keystoreProperties.getProperty("KEY_ALIAS")
                keyPassword = keystoreProperties.getProperty("KEY_PASSWORD")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    buildTypes {
        release {
            // The task guard below prevents a release artifact from being
            // produced with the public debug key when signing is not configured.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

tasks.configureEach {
    if (name.contains("Release", ignoreCase = true)) {
        doFirst {
            check(keystorePropertiesFile.exists()) {
                "Release signing is required. Copy android/app/key.properties.example " +
                    "to android/app/key.properties and provide the upload keystore values."
            }
        }
    }
}

// home_widget 0.8.1 uses the dynamic `1.+` Glance selector. Pin all Glance
// artifacts to the latest stable line supported by this project's AGP instead
// of resolving a future alpha release that requires a newer Android toolchain.
configurations.configureEach {
    resolutionStrategy.eachDependency {
        if (requested.group == "androidx.glance") {
            useVersion("1.1.1")
            because("Glance 1.3 alpha requires AGP 9.1 and compileSdk 37")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
