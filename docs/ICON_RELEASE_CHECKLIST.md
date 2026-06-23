# App Icon Release Checklist

Use this checklist before each release to ensure app icons are properly configured and displaying correctly.

## Pre-Release Verification

### Source Icon
- [ ] `assets/images/logo/synaptix_logo.png` exists and is accessible
- [ ] Icon dimensions are at least 1024×1024 pixels
- [ ] Icon has clear contrast and is recognizable at small sizes
- [ ] Icon follows Synaptix brand guidelines

### Android Icons
- [ ] 5 icon files exist in `android/app/src/main/res/`:
  - [ ] `mipmap-mdpi/ic_launcher.png` (48×48)
  - [ ] `mipmap-hdpi/ic_launcher.png` (72×72)
  - [ ] `mipmap-xhdpi/ic_launcher.png` (96×96)
  - [ ] `mipmap-xxhdpi/ic_launcher.png` (144×144)
  - [ ] `mipmap-xxxhdpi/ic_launcher.png` (192×192)
- [ ] `android/app/src/main/AndroidManifest.xml` references `@mipmap/ic_launcher` on line 14
- [ ] All icon files are PNG format with proper transparency

### iOS Icons
- [ ] 15 icon files exist in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- [ ] All icons referenced in `Contents.json` have corresponding PNG files
- [ ] iPhone icons:
  - [ ] 20×20 @2x (40×40) - Spotlight on iPhone
  - [ ] 20×20 @3x (60×60) - Spotlight on iPhone 6+
  - [ ] 29×29 @1x (29×29) - Settings on iPhone 4s
  - [ ] 29×29 @2x (58×58) - Settings on iPhone 5+
  - [ ] 29×29 @3x (87×87) - Settings on iPhone 6+
  - [ ] 40×40 @2x (80×80) - Spotlight on iPhone 5+
  - [ ] 40×40 @3x (120×120) - Spotlight on iPhone 6+
  - [ ] 60×60 @2x (120×120) - App icon on iPhone 5+
  - [ ] 60×60 @3x (180×180) - App icon on iPhone 6+
- [ ] iPad icons:
  - [ ] 20×20 @1x (20×20) - Notification on iPad
  - [ ] 20×20 @2x (40×40) - Notification on iPad
  - [ ] 29×29 @1x (29×29) - Settings on iPad
  - [ ] 29×29 @2x (58×58) - Settings on iPad
  - [ ] 40×40 @1x (40×40) - Spotlight on iPad
  - [ ] 40×40 @2x (80×80) - Spotlight on iPad
  - [ ] 76×76 @1x (76×76) - App icon on iPad
  - [ ] 76×76 @2x (152×152) - App icon on iPad
  - [ ] 83.5×83.5 @2x (167×167) - App icon on iPad Pro
- [ ] Marketing icon:
  - [ ] 1024×1024 @1x - App Store

### Web Icons
- [ ] `web/favicon.png` exists (minimum 16×16, recommended 32×32 or 64×64)
- [ ] `web/icons/Icon-192.png` exists (192×192) for PWA home screen
- [ ] `web/icons/Icon-512.png` exists (512×512) for PWA splash screen
- [ ] `web/icons/Icon-maskable-192.png` exists for adaptive icons (Chrome, Edge)
- [ ] `web/icons/Icon-maskable-512.png` exists for adaptive icons
- [ ] `web/index.html` references favicon on line 30:
  ```html
  <link rel="icon" type="image/png" href="favicon.png"/>
  ```
- [ ] `web/index.html` references apple-touch-icon on line 27:
  ```html
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  ```
- [ ] `web/manifest.json` contains all 4 icons in icons array
- [ ] Web icons have transparent backgrounds (PNG format)

## Build Testing

### Android Build Test
```bash
flutter build apk --release
# or for release to Play Store
flutter build appbundle --release
```

After building:
- [ ] Open APK/AAB in Android Studio or device
- [ ] App icon displays correctly on home screen
- [ ] App icon displays correctly in app drawer
- [ ] App icon displays correctly in app switcher/recents
- [ ] Icon has no pixelation or blurring at any density
- [ ] Icon colors match brand guidelines

### iOS Build Test
```bash
flutter build ios --release
```

Testing:
- [ ] Build succeeds without icon-related warnings
- [ ] Preview app icon in Xcode Assets.xcassets
- [ ] Install on simulator and verify home screen icon
- [ ] Install on physical device and verify
- [ ] Icon displays correctly in app switcher
- [ ] Icon displays correctly in Settings app (if applicable)
- [ ] No transparency issues on different wallpapers

### Web Build Test
```bash
flutter build web --release
```

Testing:
- [ ] Browser favicon displays in browser tab
- [ ] Favicon displays in browser history/bookmarks
- [ ] PWA "Add to Home Screen" prompt shows correct icon
- [ ] Maskable icon displays correctly in adaptive icon containers
- [ ] On Android (via Chrome): Add to Home Screen shows correct icon
- [ ] Icon looks good at small sizes (favicon)

## Configuration Files Summary

| File | Status | Notes |
|------|--------|-------|
| pubspec.yaml | ✅ Configured | Contains flutter_launcher_icons config |
| android/app/src/main/AndroidManifest.xml | ✅ Configured | References @mipmap/ic_launcher |
| ios/Runner/Assets.xcassets/AppIcon.appiconset/ | ✅ Configured | 15 PNG files + Contents.json |
| web/index.html | ✅ Configured | Favicon and apple-touch-icon links |
| web/manifest.json | ✅ Configured | PWA icon array with 4 icons |
| assets/images/logo/synaptix_logo.png | ✅ Present | Master source (1389×1389px) |

## Regenerating Icons

If icons need to be regenerated from source:

```bash
# Clean dependencies and build files
flutter clean

# Get dependencies
flutter pub get

# Run flutter_launcher_icons to regenerate all platform icons
dart run flutter_launcher_icons

# Verify changes
git diff --name-only  # Should show modified icon files
```

## Common Issues & Solutions

### Icons Not Updating on Device
- Clear app cache: Settings → Apps → [App Name] → Storage → Clear Cache
- Uninstall and reinstall the app
- Rebuild with `flutter clean` first

### Pixelated Icons on Android
- Ensure icons are at least 192×192 for xxxhdpi (highest density)
- Check if all density variants are present
- Run `dart run flutter_launcher_icons` to regenerate

### Icons Not Showing on iOS
- Verify all 15 icon files exist in AppIcon.appiconset
- Check Contents.json references correct filenames
- Clean Xcode build: `rm -rf ios/Pods && rm -rf ios/Podfile.lock`

### Web Favicon Not Updating
- Clear browser cache (Ctrl+Shift+Delete or Cmd+Shift+Delete)
- Use incognito/private mode to test
- Check browser DevTools → Network for favicon request
- Ensure `web/favicon.png` is served with correct MIME type

### PWA Icons Not Showing (Web)
- Verify `web/manifest.json` exists and is valid JSON
- Check manifest.json is referenced in `web/index.html` line 33
- Ensure all icon sizes match manifest definitions
- Test with: `flutter build web --release && python3 -m http.server 8000`

## Release Sign-Off

Before final release:
- [ ] All platform icons verified visually
- [ ] No console warnings or errors during build
- [ ] Icons tested on at least one device per platform
- [ ] Icon brand consistency confirmed
- [ ] No regressions from previous releases
- [ ] Team lead has approved icons

## Documentation Updates

After release:
- [ ] Update this checklist with any issues encountered
- [ ] Document any platform-specific icon customizations
- [ ] Record icon source version (synaptix_logo.png modification date)
- [ ] Add release date to ICON_SETUP_GUIDE.md

---

**Last Updated**: 2026-06-23  
**Icon Source**: assets/images/logo/synaptix_logo.png (1389×1389px)  
**Configuration Version**: pubspec.yaml flutter_launcher_icons section
