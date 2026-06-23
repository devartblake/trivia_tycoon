# App Icon Setup Guide

## Overview

This guide documents the app icon configuration for the Synaptix Flutter application. The app uses the **Synaptix logo** (`assets/images/logo/synaptix_logo.png`) as the source for generating app icons across all platforms.

## Current Configuration

### Source Asset
- **Primary Icon Source**: `assets/images/logo/synaptix_logo.png`
- **Format**: PNG image (1389 × 1389 px, ~1.4 MB)
- **Usage**: Master source for all platform-specific icons

### Configured Platforms

#### 1. **Android**
- **Configuration File**: `android/app/src/main/AndroidManifest.xml`
- **Icon References**: `@mipmap/ic_launcher`
- **Icon Locations**: 
  - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
  - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- **Status**: ✅ All 5 density variants present

#### 2. **iOS**
- **Configuration File**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
- **Icon Location**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Icon Count**: 15 image assets (various sizes for iPhone, iPad, and marketing)
- **Sizes Included**:
  - iPhone: 20×20 (2x, 3x), 29×29 (1x, 2x, 3x), 40×40 (2x, 3x), 60×60 (2x, 3x)
  - iPad: 20×20 (1x, 2x), 29×29 (1x, 2x), 40×40 (1x, 2x), 76×76 (1x, 2x), 83.5×83.5 (2x)
  - Marketing: 1024×1024 (1x)
- **Status**: ✅ All 15 assets present

#### 3. **Web**
- **Configuration File**: `web/manifest.json` and `web/index.html`
- **Icon Locations**:
  - `web/icons/Icon-192.png` (192×192 px)
  - `web/icons/Icon-512.png` (512×512 px)
  - `web/icons/Icon-maskable-192.png` (192×192 px, maskable)
  - `web/icons/Icon-maskable-512.png` (512×512 px, maskable)
  - `web/favicon.png` (favicon)
- **Favicon Reference**: `web/index.html` line 30
- **Manifest Integration**: `web/manifest.json` includes all icon definitions
- **Status**: ✅ All web icons configured

## Automated Icon Generation

### Using flutter_launcher_icons

To regenerate all platform icons from the Synaptix logo, follow these steps:

#### Prerequisites
- Flutter SDK installed and in PATH
- `flutter_launcher_icons` package (already in `pubspec.yaml`)

#### Generate Icons

1. **Ensure dependencies are up to date**:
   ```bash
   flutter pub get
   ```

2. **Generate icons for all platforms**:
   ```bash
   dart run flutter_launcher_icons
   ```

3. **Generate icons for specific platforms**:
   ```bash
   dart run flutter_launcher_icons:main -w  # Web only
   dart run flutter_launcher_icons:main -a  # Android only
   dart run flutter_launcher_icons:main -i  # iOS only
   ```

### Configuration Reference

The flutter_launcher_icons configuration is in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/logo/synaptix_logo.png"
  image_path_android: "assets/images/logo/synaptix_logo.png"
  image_path_ios: "assets/images/logo/synaptix_logo.png"
  web:
    generate: true
    image_path: "assets/images/logo/synaptix_logo.png"
    background_color: "#0175C2"
    theme_color: "#0175C2"
  windows:
    generate: false
  macos:
    generate: false
```

## Build Verification

### Android Release Build

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

The app icon will appear:
1. On the device home screen
2. In the app drawer
3. In app switcher/recents menu

### iOS Release Build

```bash
flutter build ios --release
```

Verify the app icon in:
1. Xcode Assets.xcassets preview
2. iOS Simulator home screen
3. TestFlight/App Store preview

### Web Release Build

```bash
flutter build web --release
```

Verify:
1. Browser tab favicon
2. PWA install prompt (if enabled)
3. Browser bookmark icon

## Icon Requirements by Platform

### Android
- **Minimum Size**: 192×192 pixels
- **Format**: PNG with transparency or solid background
- **Densities**: mdpi (160dpi), hdpi (240dpi), xhdpi (320dpi), xxhdpi (480dpi), xxxhdpi (640dpi)
- **Ratio**: 1:1 square

### iOS
- **Minimum Size**: 192×192 pixels (1024×1024 for app store)
- **Format**: PNG without transparency for app icon
- **Safe Zone**: Keep 10% margin from edges
- **Ratio**: 1:1 square

### Web
- **Favicon**: 16×16, 32×32, or 64×64 pixels
- **PWA Icons**: 192×192 (for Add to Home Screen), 512×512 (splash screen)
- **Maskable**: For adaptive icon displays (Chrome, Edge)
- **Format**: PNG

## Troubleshooting

### Icons Not Updating After Build

1. Clean build artifacts:
   ```bash
   flutter clean
   ```

2. Get dependencies again:
   ```bash
   flutter pub get
   ```

3. Regenerate icons:
   ```bash
   dart run flutter_launcher_icons
   ```

4. Rebuild the app:
   ```bash
   flutter build apk --release  # for Android
   flutter build ios --release  # for iOS
   flutter build web --release  # for Web
   ```

### iOS Icons Not Displaying

- Ensure all 15 icons are present in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Check `Contents.json` references correct filenames
- Clean Xcode build folder: `rm -rf ios/Pods && rm -rf ios/Podfile.lock`

### Android Icons Not Displaying

- Verify all 5 density variants exist in `android/app/src/main/res/mipmap-*/`
- Ensure `AndroidManifest.xml` references `@mipmap/ic_launcher`
- Check `android:icon` attribute in `<application>` tag

### Web Favicon Not Updating

- Clear browser cache or use incognito/private mode
- Verify `web/index.html` links to correct favicon path
- Check `web/manifest.json` icon entries

## Assets Organization

```
assets/
├── images/
│   ├── logo/
│   │   ├── synaptix_logo.png           (Master icon source)
│   │   ├── synaptix_appLogo.png
│   │   ├── appLogo.png
│   │   └── trivia_tycoon_appLogo.png
│   └── [other images...]
├── icons/
│   └── [app icons]
└── [other assets...]

ios/Runner/Assets.xcassets/
├── AppIcon.appiconset/                  (15 icon files)
│   ├── Icon-App-*.png
│   └── Contents.json

android/app/src/main/res/
├── mipmap-mdpi/                         (1 icon)
├── mipmap-hdpi/                         (1 icon)
├── mipmap-xhdpi/                        (1 icon)
├── mipmap-xxhdpi/                       (1 icon)
└── mipmap-xxxhdpi/                      (1 icon)

web/
├── favicon.png                          (1 icon)
├── icons/                               (4 icons)
│   ├── Icon-192.png
│   ├── Icon-512.png
│   ├── Icon-maskable-192.png
│   └── Icon-maskable-512.png
├── index.html
└── manifest.json
```

## Release Checklist

Before releasing the app, verify:

- [ ] Android icons display correctly in release APK/AAB
- [ ] iOS icons display correctly on device/simulator
- [ ] Web favicon displays in browser tab
- [ ] PWA icon displays for Add to Home Screen (Web)
- [ ] All platform icon colors/branding are consistent
- [ ] No pixelated or distorted icons on any device size
- [ ] Icon transparent areas display correctly on all backgrounds

## Additional Resources

- [Flutter Icons Documentation](https://flutter.dev/docs/development/ui/assets-and-images#updating-the-app-icon)
- [flutter_launcher_icons Package](https://pub.dev/packages/flutter_launcher_icons)
- [Android App Icon Guidelines](https://developer.android.com/studio/write/image-asset-studio)
- [iOS App Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/app-icon/)
- [Web PWA Icon Guidelines](https://web.dev/installable-web-apps/)

## Last Updated
- **Date**: 2026-06-23
- **Icon Source**: assets/images/logo/synaptix_logo.png
- **Configuration**: pubspec.yaml (flutter_launcher_icons section)
