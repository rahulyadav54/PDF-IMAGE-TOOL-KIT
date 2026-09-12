import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val secretsProperties = Properties()
val secretsFile = rootProject.file("secrets.local.properties")
if (secretsFile.exists()) {
    secretsProperties.load(FileInputStream(secretsFile))
}

fun isValidAdMobAppId(id: String?): Boolean {
    if (id.isNullOrEmpty()) return false
    return id.matches(Regex("""ca-app-pub-\d+~\d+"""))
}

fun resolveAdMobAppId(buildTypeDefault: String): String {
    val candidates = mutableListOf<String>()
    if (project.hasProperty("ADMOB_APP_ID")) {
        val v = project.findProperty("ADMOB_APP_ID")?.toString()
        if (!v.isNullOrEmpty()) candidates.add(v)
    }
    secretsProperties.getProperty("ADMOB_APP_ID")?.let { candidates.add(it) }
    for (candidate in candidates) {
        if (isValidAdMobAppId(candidate)) return candidate
    }
    return buildTypeDefault
}

android {
    namespace = "com.pdftoolbox.pdf_image_toolbox"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.pdftoolbox.pdf_image_toolbox"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["adMobAppId"] = "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            manifestPlaceholders["adMobAppId"] =
                resolveAdMobAppId("ca-app-pub-3940256099942544~3347511713")
        }
        debug {
            manifestPlaceholders["adMobAppId"] = "ca-app-pub-3940256099942544~3347511713"
        }
    }
}

flutter {
    source = "../.."
}
