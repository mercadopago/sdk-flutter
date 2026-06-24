allprojects {
    repositories {
        google()
        mavenCentral()
        // Required by the mercadopago_flutter_sdk plugin for the bundled
        // device-fingerprint library (com.mercadolibre.android.device:sdk).
        maven {
            url = uri("https://artifacts.mercadolibre.com/repository/android-releases")
            content {
                includeGroup("com.mercadolibre.android.device")
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
