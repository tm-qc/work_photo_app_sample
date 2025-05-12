plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.work_photo_app_sample.work_photo_app_sample"
    compileSdk = flutter.compileSdkVersion
//    本来はflutter.ndkVersionで良いはずだが、キャッシュ消してもなぜか26.3.11579264が復活するので、27.0.12077973を直接指定するしかない
//    ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.work_photo_app_sample.work_photo_app_sample"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
// TODO:ずっとわからない minSdk = flutter.minSdkVersion の確認方法について
//
// Shared preferencesならAndorid SDK 16 以上
// cameraならならAndorid SDK 21 以上
//
//  現状以下の仕様らしい
//  minSdk = flutter.minSdkVersion のままだと、Flutter内部で定義された**デフォルト値「16」**が使われる
//
//  現状今のバージョン、本当に既定が16なのかのシンプルな確認方法がない
//  過去に「Android SDK version 35.0.1」OKと結論だったが、結局既定が16以上だからのこじつけの話だし、明確に確認する方法がない
//
//  一旦cameraが本当に動かないのか確認してみる
//  動かないならminSdk = flutter.minSdkVersion→minSdk = 21に変更する
//  影響がわからないから怖いが
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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

flutter {
    source = "../.."
}
