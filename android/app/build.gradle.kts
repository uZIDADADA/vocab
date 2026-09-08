plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystorePath = providers.environmentVariable("VOCAB_RELEASE_KEYSTORE").orNull
val releaseStorePassword = providers.environmentVariable("VOCAB_RELEASE_STORE_PASSWORD").orNull
val releaseKeyAlias = providers.environmentVariable("VOCAB_RELEASE_KEY_ALIAS").orNull
val releaseKeyPassword = providers.environmentVariable("VOCAB_RELEASE_KEY_PASSWORD").orNull
val releaseStoreType = providers.environmentVariable("VOCAB_RELEASE_STORE_TYPE").orElse("PKCS12").get()
val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (
    isReleaseBuild &&
    listOf(
        releaseKeystorePath,
        releaseStorePassword,
        releaseKeyAlias,
        releaseKeyPassword,
    ).any { it.isNullOrBlank() }
) {
    throw GradleException(
        "Android release signing is not configured. " +
            "Run tool/setup_android_release_signing_macos.sh or provide the VOCAB_RELEASE_* environment variables.",
    )
}

android {
    namespace = "io.github.uzidadada.vocab"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.github.uzidadada.vocab"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            releaseKeystorePath?.let { storeFile = file(it) }
            releaseStorePassword?.let { storePassword = it }
            releaseKeyAlias?.let { keyAlias = it }
            releaseKeyPassword?.let { keyPassword = it }
            storeType = releaseStoreType
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
