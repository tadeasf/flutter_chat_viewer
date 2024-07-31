# flutter_chat_viewer

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

For Android and iOS apps built with Flutter, the launcher icons and splash screen assets are typically stored in different locations than the web directory. Here's where you can find and update these assets:

Launcher Icons:
For Android:

Path: android/app/src/main/res/
You'll find multiple directories like mipmap-hdpi, mipmap-mdpi, mipmap-xhdpi, etc.
Replace ic_launcher.png in each of these directories with your icon in the appropriate size.

For iOS:

Path: ios/Runner/Assets.xcassets/AppIcon.appiconset/
Replace the existing icon files with your own, maintaining the same file names and sizes.

Splash Screen:
For Android:

Path: android/app/src/main/res/drawable/
Create or modify launch_background.xml

For iOS:

Path: ios/Runner/Assets.xcassets/LaunchImage.imageset/
Replace the existing images with your splash screen images

However, manually replacing these assets can be tedious. A easier way to manage icons and splash screens is to use a package like flutter_launcher_icons and flutter_native_splash. Here's how you can use them:

Add these to your pubspec.yaml under dev_dependencies:
yamlCopydev_dependencies:
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.1

Run flutter pub get
For launcher icons, create a config section in pubspec.yaml:
yamlCopyflutter_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"

For splash screen, add a config section:
yamlCopyflutter_native_splash:
  color: "#42a5f5"
  image: assets/splash.png

Run these commands:
Copyflutter pub run flutter_launcher_icons:main
flutter pub run flutter_native_splash:create

build signed apk from appbundle:

```sh
bundletool build-apks --bundle=/Users/tadeasfort/Documents/coding_projects/flutter_chat_viewer/build/app/outputs/bundle/release/app-release.aab \
--output=/Users/tadeasfort/Documents/coding_projects/flutter_chat_viewer/build/app/outputs/apk/app-release.apks \
--ks=/Users/tadeasfort/key.jks \
--ks-pass=pass:pass \
--ks-key-alias=key \
--key-pass=pass:pass
```

verify built apks:

```sh
jarsigner -verify -verbose -certs /Users/tadeasfort/Documents/coding_projects/flutter_chat_viewer/build/app/outputs/flutter-apk/app-release.apk
```
