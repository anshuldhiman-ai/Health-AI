allprojects {
    repositories {
        google()
        mavenCentral()
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

// Align Java/Kotlin JVM targets for every plugin subproject. Flutter
// plugins mix Java and Kotlin sources and frequently disagree (e.g.
// Java 11 vs Kotlin 17), which fails the release build with
// "Inconsistent JVM Target Compatibility". :app already pins 17.
// afterEvaluate runs AFTER each plugin's own build script, so plugins
// cannot overwrite it. :app is skipped — evaluationDependsOn above
// forces its evaluation during THIS script, and afterEvaluate on an
// already-evaluated project throws.
subprojects {
    if (name != "app") {
        afterEvaluate {
            extensions.findByName("android")
                ?.let { it as? com.android.build.gradle.LibraryExtension }
                ?.compileOptions
                ?.let {
                    it.sourceCompatibility = JavaVersion.VERSION_17
                    it.targetCompatibility = JavaVersion.VERSION_17
                }
            extensions.findByName("kotlin")
                ?.let { it as? org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension }
                ?.compilerOptions
                ?.jvmTarget
                ?.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
