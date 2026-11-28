import java.util.Properties
import java.util.Base64
import com.google.gms.googleservices.GoogleServicesTask
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
// Isolated, minified release regression check. Never installed over the Play app.
val reminderReleaseSmoke = providers.gradleProperty("dart-defines").orNull
    ?.split(",")?.any {
        String(Base64.getDecoder().decode(it), Charsets.UTF_8) == "REMINDER_RELEASE_SMOKE=true"
    } == true
val reminderWirelessTest = providers.gradleProperty("dart-defines").orNull
    ?.split(",")?.any {
        String(Base64.getDecoder().decode(it), Charsets.UTF_8) == "REMINDER_WIRELESS_TEST=true"
    } == true
require(!(reminderReleaseSmoke && reminderWirelessTest)) { "Choose one isolated test mode." }
require(!reminderWirelessTest || gradle.startParameter.taskNames.none {
    it.contains("release", ignoreCase = true) || it.contains("profile", ignoreCase = true)
}) { "The full wireless test app must use a debug build." }

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
println("key.properties exists: ${keystorePropertiesFile}")
println("key.properties exists: ${keystorePropertiesFile.exists()}")

android {
    namespace = "com.sundaram.germanreminder.app"
    compileSdk = 36
    //buildToolsVersion = "35.0.0"
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = when {
            reminderReleaseSmoke -> "com.sundaram.germanreminder.releasecheck"
            reminderWirelessTest -> "com.sundaram.germanreminder.wirelesstest"
            else -> "com.sundaram.germanreminder.app"
        }
        manifestPlaceholders["applicationLabel"] = when {
            reminderReleaseSmoke -> "German Reminder Release Check"
            reminderWirelessTest -> "German Reminder Test"
            else -> "German Reminder"
        }
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    println("Keystore path: ${keystoreProperties["storeFile"]}")
    println("Key alias: ${keystoreProperties["keyAlias"]}")
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    if (reminderReleaseSmoke) {
        sourceSets.getByName("release").manifest.srcFile("src/releaseSmoke/AndroidManifest.xml")
    }

}
tasks.configureEach {
    if (reminderReleaseSmoke && name.endsWith("GoogleServices")) enabled = false
}
afterEvaluate {
    tasks.withType<GoogleServicesTask>().configureEach {
        if (reminderWirelessTest) {
            googleServicesJsonFiles.set(listOf(rootProject.file("../.local-tools/wireless-google-services.json")))
        }
    }
}
flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
