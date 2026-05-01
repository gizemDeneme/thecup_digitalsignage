plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.thecup.thecup"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        create("release") {
            storeFile = file("../thecup-release.jks")
            storePassword = "thecup2024!"
            keyAlias = "thecup"
            keyPassword = "thecup2024!"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"

    productFlavors {
        create("admin") {
            dimension = "app"
            applicationId = "com.thecup.admin"
            resValue("string", "app_name", "thecup Admin")
        }
        create("tv") {
            dimension = "app"
            applicationId = "com.thecup.tv"
            resValue("string", "app_name", "thecup Ekran")
            minSdk = flutter.minSdkVersion
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
