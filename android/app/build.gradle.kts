plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.docasa_app"
    // permission_handler_android requires API 37 (D-017).
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications requires core library desugaring.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        // `-PdemoBuild=true` (tools/build-demo-apk.sh) produces the parallel-install
        // demo artifact: separate applicationId + launcher label, emulator mode.
        // `-PrealBle=true` (tools/build-ble-test-apk.sh) swaps in the flutter_blue_plus
        // transport (D-017) — for G4 testing before the bench session (D-019).
        val demoBuild = findProperty("demoBuild") == "true"
        val realBle = findProperty("realBle") == "true"
        applicationId = when {
            realBle -> "com.example.docasa_app.ble"
            demoBuild -> "com.example.docasa_app.demo"
            else -> "com.example.docasa_app"
        }
        manifestPlaceholders["appName"] = when {
            // D-039: the BLE build ships as simply "DOCASA" (user request);
            // the demo keeps its distinct label for parallel installs.
            realBle -> "DOCASA"
            demoBuild -> "DOCASA Demo"
            else -> "docasa_app"
        }
        // FT-3 requires BLE-only device discovery (D-009): minSdk 26.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
