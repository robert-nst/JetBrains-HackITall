# Program on the Go Plugin

<div style="display: flex; align-items: center;">
  <img src="https://resources.jetbrains.com/storage/products/company/brand/logos/jetbrains.svg" alt="JetBrains Logo" style="height: 50px; margin-right: 20px;">
  <img src="mobile/assets/app_icon.png" alt="Our Logo" style="height: 30px;">
</div>

## Overview

**Program on the Go** is an IntelliJ plugin that creates an embedded server every time a new IDE instance is launched. When the server is running, the plugin displays a public URL (generated via **ngrok**) and a corresponding QR code in the side toolbar.

Using our dedicated Flutter mobile app, you can scan the QR code to trigger remote builds. If a build fails, the plugin utilizes the **OpenAI API** to analyze the error output, provide a simplified explanation, and generate a potential solution. The plugin can then automatically apply code modifications and allows you to rerun the build cycle until a successful build is achieved.

This plugin was developed for the **HackITall II Hackathon** with the main sponsorship of **JetBrains**.

## Features

- **Embedded Server:** Automatically starts an embedded server when a new IntelliJ instance opens.
- **Public URL & QR Code:** Generates a public URL (using ngrok) and a matching QR code in the IDE's side toolbar.
- **Remote Build via Flutter Mobile App:** Scan the QR code with our Flutter app to build applications remotely.
- **Build Suggestions:** If a build fails, the plugin uses the OpenAI API to provide simple error explanations and generate possible code fixes.
- **Automatic Code Modification:** Applies the generated fixes directly in your code, with an option to rerun the build.

## Running the Plugin

To run the plugin, you can use the provided Gradle run configuration. For example, run the following command in your project directory:

```bash
./gradlew runIde
```

This will launch a new instance of IntelliJ with the plugin enabled.
> You can just run the plugin form the Intellij IDEA IDE, using the integrated Gradle configurations (using the main run button or using the side panel).

## Running the Flutter Mobile App

To run the Flutter mobile app, execute the following commands:

```bash
flutter pub get
flutter pub run flutter_native_splash:create
flutter pub run flutter_launcher_icons:main
flutter run
```

These commands will set up the app assets and launch the mobile application.

## References

- [OpenAI API Documentation](https://platform.openai.com/docs)
- [JetBrains IDE Plugin Development Course](https://plugins.jetbrains.com/plugin/25398-ide-plugin-development-course)
- [ngrok Documentation](https://ngrok.com/docs)
- [IntelliJ Platform Plugin Template](https://lp.jetbrains.com/intellij-platform-plugin-template/)
- [IDE Workshop Tutorial (JetBrains Research)](https://github.com/JetBrains-Research/ide-workshop-tutorial)
- [LLM Integration Plugin Template (JetBrains Research)](https://github.com/JetBrains-Research/llm-integration-plugin-template)

