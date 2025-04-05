plugins {
    id("java")
    id("org.jetbrains.kotlin.jvm") version "1.9.25"
    id("org.jetbrains.intellij") version "1.17.4"
}

group = "com.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

// Exclude conflicting SLF4J modules from all configurations.
configurations.all {
    exclude(group = "org.slf4j", module = "slf4j-jul")
    exclude(group = "org.slf4j", module = "slf4j-jdk14")
}

dependencies {
    // Use only the SLF4J API (no binding)
    implementation("org.slf4j:slf4j-api:1.7.36")

    // ZXing for QR code generation
    implementation("com.google.zxing:core:3.5.0")
    // Gson for JSON conversion
    implementation("com.google.code.gson:gson:2.8.9")

    implementation("io.github.cdimascio:dotenv-java:2.2.0")
}

// Configure Gradle IntelliJ Plugin
// Read more: https://plugins.jetbrains.com/docs/intellij/tools-gradle-intellij-plugin.html
intellij {
    version.set("2024.1.7")
    type.set("IC") // Target IDE Platform

    plugins.set(listOf(/* Plugin Dependencies */))
}

tasks {
    // Set the JVM compatibility versions
    withType<JavaCompile> {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
    withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        kotlinOptions.jvmTarget = "17"
    }

    patchPluginXml {
        sinceBuild.set("241")
        untilBuild.set("243.*")
    }

    signPlugin {
        certificateChain.set(System.getenv("CERTIFICATE_CHAIN"))
        privateKey.set(System.getenv("PRIVATE_KEY"))
        password.set(System.getenv("PRIVATE_KEY_PASSWORD"))
    }

    publishPlugin {
        token.set(System.getenv("PUBLISH_TOKEN"))
    }
}
