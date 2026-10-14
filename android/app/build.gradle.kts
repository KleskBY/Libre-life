import java.util.Properties

plugins {
    id("com.android.application")
}

// Upload signing. Keys and passwords never live in the repo: create android/keystore.properties
// (gitignored) or set UPLOAD_KEYSTORE / UPLOAD_KEYSTORE_PASSWORD / UPLOAD_KEY_ALIAS /
// UPLOAD_KEY_PASSWORD in the environment. Without them the release build stays unsigned.
val keystoreProps = Properties().apply {
    val f = rootProject.file("keystore.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun signingValue(key: String, env: String): String? =
    (keystoreProps.getProperty(key) ?: System.getenv(env))?.takeIf { it.isNotBlank() }

val keystorePath = signingValue("storeFile", "UPLOAD_KEYSTORE")
val keystorePassword = signingValue("storePassword", "UPLOAD_KEYSTORE_PASSWORD")
val keystoreAlias = signingValue("keyAlias", "UPLOAD_KEY_ALIAS")
val keystoreKeyPassword = signingValue("keyPassword", "UPLOAD_KEY_PASSWORD") ?: keystorePassword
val hasSigningConfig = keystorePath != null && keystorePassword != null && keystoreAlias != null

val buildRoot = providers.gradleProperty("zircon.buildRoot").getOrElse("${rootDir}/build-out")
layout.buildDirectory.set(file("$buildRoot/app"))

android {
    namespace = "by.quake.zircon"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "by.quake.zircon"
        minSdk = 26
        targetSdk = 36
        // Play needs a higher versionCode for every upload:
        //   ./gradlew bundleObjectnRelease -Pzircon.versionCode=2 -Pzircon.versionName=0.2.0
        versionCode = (providers.gradleProperty("zircon.versionCode").orNull ?: "1").toInt()
        versionName = providers.gradleProperty("zircon.versionName").orNull ?: "0.1.0"

        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
        externalNativeBuild {
            cmake {
                arguments += listOf("-DANDROID_STL=c++_shared", "-DANDROID_PLATFORM=android-26")
                // -Pzircon.engineDir=<path> builds against another Zircon tree (engine upgrades)
                providers.gradleProperty("zircon.engineDir").orNull?.let {
                    arguments += "-DENGINE_DIR=$it"
                }
                // debug variants otherwise build the engine unoptimized, several times slower on device
                cFlags += listOf("-O2")
                cppFlags += listOf("-O2")
            }
        }
    }

    buildFeatures {
        buildConfig = true
        resValues = true
    }

    // Game-specific behavior lives in FlavorProfile.java under src/<flavor>/java.
    // -Pzircon.gameFolder=<path> overrides where the built app looks for game data.
    // Relative paths resolve against shared storage, absolute paths are used as given.
    val gameFolderOverride = providers.gradleProperty("zircon.gameFolder").orNull

    flavorDimensions += "game"
    productFlavors {
        // Libre-life: the player supplies the game data folder, like the Quake flavor.
        create("librelife") {
            dimension = "game"
            applicationId = "by.quake.zircon.librelife"
            resValue("string", "app_name", "Libre-life")
            resValue("string", "default_game_folder", gameFolderOverride ?: "LibreLife")
            externalNativeBuild { cmake { arguments += "-DZIRCON_GAME=LIBRE_LIFE" } }
        }
        // ObjectN keeps its published Play identity; its data pk3 is generated, not stored in git.
        create("objectn") {
            dimension = "game"
            applicationId = "by.quake.objectn"
            resValue("string", "app_name", "ObjectN")
            resValue("string", "default_game_folder", "")   // data ships inside the app
            externalNativeBuild { cmake { arguments += "-DZIRCON_GAME=OBJECTN" } }
        }
        // Stock Quake on the same engine and touch shell; reads the player's own data from shared storage.
        create("quake") {
            dimension = "game"
            applicationIdSuffix = ".quake"
            resValue("string", "app_name", "Zircon Quake")
            resValue("string", "default_game_folder", gameFolderOverride ?: "Quake/Q1")
            externalNativeBuild { cmake { arguments += "-DZIRCON_GAME=QUAKE" } }
        }
    }

    sourceSets {
        // the ObjectN pk3 is generated into src/main/assets by tools/package_android.py
        getByName("main").assets.setSrcDirs(emptyList<String>())
        getByName("objectn").assets.srcDir("src/main/assets")
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.31.6"
            buildStagingDirectory = file("$buildRoot/cxx")
        }
    }

    signingConfigs {
        if (hasSigningConfig) {
            create("upload") {
                storeFile = file(keystorePath!!)
                storePassword = keystorePassword
                keyAlias = keystoreAlias
                keyPassword = keystoreKeyPassword
                enableV1Signing = false   // Play only needs v2/v3 for minSdk 26
                enableV2Signing = true
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            ndk {
                debugSymbolLevel = "FULL"   // native crash reports readable in Play Console
            }
            if (hasSigningConfig) {
                signingConfig = signingConfigs.getByName("upload")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    androidResources {
        noCompress += listOf("pk3", "pak")
    }

    lint {
        abortOnError = false
    }
}
