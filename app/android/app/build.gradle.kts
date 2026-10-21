plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.anshuldhiman.app"
    // Pinned per CLAUDE.md Section 7.2 (Play requirement as of Aug 2026:
    // target API 36). Re-verify before each release — this changes yearly.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (java.time APIs on
        // minSdk < 34). Pin verified on Maven Central; bump deliberately.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO(placeholder): MUST be final before the first Play upload —
        // it cannot change afterwards (CLAUDE.md Section 0).
        applicationId = "com.anshuldhiman.app"
        // minSdk 26 per CLAUDE.md Section 7.2; raise only with a reason.
        minSdk = 26
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Note: Use `flutter build apk --split-per-abi` from Flutter CLI rather than
    // enabling AGP splits here, preventing APK output path lookup errors.

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // R8 minification stays ON (smaller APK), but the app relies
            // on plugins that resolve classes BY NAME at runtime
            // (shared_preferences via JNI, path_provider, health, Tink).
            // The matching keep rules live in proguard-rules.pro.
            isMinifyEnabled = true
            // Resource shrinking is OFF: Flutter keeps its assets in
            // assets/, but the engine also loads some Android resources
            // reflectively, and a stripped resource shows up as a blank
            // window with no logcat error. Keep it on only after the
            // release APK is verified on a real device.
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring (see compileOptions above).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
