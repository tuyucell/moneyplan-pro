import com.android.build.api.dsl.LibraryExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.api.tasks.compile.JavaCompile

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

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

subprojects {
    if (name == "home_widget") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension> {
                compileOptions {
                    // The plugin is compiled for Java 8. Align both tasks to
                    // Java 11, which is sufficient for Glance 1.1 and avoids
                    // a Kotlin/Java target mismatch on modern Gradle.
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
            }
        }
        afterEvaluate {
            tasks.withType<JavaCompile>().configureEach {
                sourceCompatibility = JavaVersion.VERSION_11.toString()
                targetCompatibility = JavaVersion.VERSION_11.toString()
            }
            tasks.withType<KotlinCompile>().configureEach {
                compilerOptions.jvmTarget.set(JvmTarget.JVM_11)
            }
        }
    }
}

// home_widget's own build script resets its Java target late in evaluation.
// Apply the final target after every Android subproject has been configured.
gradle.projectsEvaluated {
    project(":home_widget").tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_11.toString()
        targetCompatibility = JavaVersion.VERSION_11.toString()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
