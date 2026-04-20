plugins {
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.2" apply false
}

val flutterProjectRoot = rootProject.projectDir.parentFile

rootProject.layout.buildDirectory.set(File(flutterProjectRoot, "build"))

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    project.layout.buildDirectory.set(File(flutterProjectRoot, "build/${project.name}"))
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                if (compileSdk == null || compileSdk == 0) {
                    compileSdk = 35
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
