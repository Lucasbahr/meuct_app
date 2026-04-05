import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugin deve vir depois
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.meuct_app"
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
        applicationId = "com.suaacademia.genesismma"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Para produção real: usar keystore de release
            // Aqui mantém debug só para facilitar testes locais
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    @Suppress("DEPRECATION")
    applicationVariants.configureEach {
        val variant = this

        outputs.configureEach {
            val out = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl

            val versionName = variant.versionName
            val versionCode = variant.versionCode

            out.outputFileName =
                "genesismma-${variant.buildType.name}-v${versionName}-build${versionCode}.apk"
        }
    }
}

flutter {
    source = "../.."
}