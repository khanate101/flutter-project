# StatusVault

StatusVault is a Flutter app for viewing, saving, and organizing local media/status files.

## Supported targets

- Android: reads a user-selected status folder through Android's Storage Access Framework and can save media to `Pictures/StatusVault` through MediaStore.
- Web: uses the browser file picker. The browser cannot access a WhatsApp folder directly, so the user selects image/video files manually. Saving downloads the selected media through the browser.

## Android build

```bash
flutter clean
rm -rf android/.gradle build
flutter pub get
flutter build apk --release
```

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For ABI-specific APKs:

```bash
flutter build apk --release --split-per-abi
```

## Web build

```bash
flutter clean
flutter pub get
flutter build web --release
```

The web build is generated in:

```text
build/web
```

The Android and web implementations are separated with Dart conditional imports, so Android-only APIs such as `dart:io`, MethodChannel storage access, and `photo_manager` are not compiled into the web target.

## Important

The Android release build is configured with debug signing so a local APK can be generated. Before publishing to Google Play, configure a real release keystore and signing configuration.
