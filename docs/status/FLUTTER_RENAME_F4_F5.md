# Flutter Tycoon → Synaptix rename — Waves F4 + F5

**Date:** 2026-07-13  
**Repo:** `trivia_tycoon` folder (package name is now `synaptix`)  
**Depends on:** [F1–F3](FLUTTER_RENAME_F1_F2_F3.md)

---

## Wave F4 — Dart package name + imports

| Before | After |
|--------|--------|
| `pubspec.yaml` `name: trivia_tycoon` | `name: synaptix` |
| `package:trivia_tycoon/...` | `package:synaptix/...` |

| Metric | Value |
|--------|--------|
| Dart files rewritten | 653 |
| Import occurrences | 1,550 |
| Residual `package:trivia_tycoon/` | **0** |

**Not renamed (F6 / process):** git remote path, local folder name `trivia_tycoon`, `.iml` module filenames, clone URL in README.

**Tooling comments:** `scripts/generate_proto.ps1` / `.sh` headers updated to say “synaptix Flutter”.

---

## Wave F5 — Platform IDs / binaries

### Mapping

| Kind | Before | After |
|------|--------|--------|
| Android `namespace` / `applicationId` | `com.theoreticalmindstech.trivia_tycoon` | `com.theoreticalmindstech.synaptix` |
| Android Kotlin package + path | `…/trivia_tycoon/*.kt` | `…/synaptix/*.kt` |
| Android keystore alias | `trivia_tycoon_secure_store_key` | `synaptix_secure_store_key` |
| iOS `PRODUCT_BUNDLE_IDENTIFIER` | `…triviaTycoon` (+ RunnerTests) | `…synaptix` |
| iOS `CFBundleName` | `trivia_tycoon` | `synaptix` |
| macOS `PRODUCT_NAME` / bundle | `trivia_tycoon` / `…triviaTycoon` | `synaptix` / `…synaptix` |
| macOS product / scheme | `trivia_tycoon.app` | `synaptix.app` |
| Linux `BINARY_NAME` / `APPLICATION_ID` | `trivia_tycoon` / `…trivia_tycoon` | `synaptix` / `…synaptix` |
| Linux window title | `trivia_tycoon` | `Synaptix` |
| Windows project / `BINARY_NAME` | `trivia_tycoon` | `synaptix` |
| Windows exe metadata | `trivia_tycoon.exe` | `synaptix.exe` |
| Windows env | `TRIVIA_TYCOON_ENV`, `TRIVIA_TYCOON_DEBUG_BUILD` | `SYNAPTIX_ENV`, `SYNAPTIX_DEBUG_BUILD` |
| Windows dart arg | `--trivia-env=` | `--synaptix-env=` |
| Windows log prefix | `[trivia_tycoon]` | `[synaptix]` |

Display names (Android label, iOS CFBundleDisplayName, web) were already **Synaptix** from earlier work.

### Breaking / ops notes

1. **Store identity:** New `applicationId` / bundle IDs install as a **different app** unless you use Play App Signing / App Store continuity tooling. Plan store listings before shipping.
2. **Android secure store alias change** + new applicationId → clean local sandbox; prior encrypted secrets not carried over.
3. **Windows:** set `SYNAPTIX_ENV=staging` (was `TRIVIA_TYCOON_ENV`).
4. **`flutter` CLI was not on PATH** in this environment — run locally:
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   ```

---

## Residual intentionally left (Wave F6 / docs)

| Item | Why |
|------|-----|
| Folder / git clone name `trivia_tycoon` | Repo rename (F6) |
| `trivia_tycoon.iml`, `android/trivia_tycoon_android.iml` | IDE module rename (F6) |
| Historical `docs/**` migration narratives | F-docs |
| Asset `trivia_tycoon_appLogo.png` (unused by pubspec icons) | F6 optional |
| Product description still says “trivia platform” | Brand language, not product code name |

---

## Verify checklist

```text
# F4
rg "package:trivia_tycoon" lib test   # expect 0
head -1 pubspec.yaml                  # name: synaptix

# F5 platforms
rg "trivia_tycoon|triviaTycoon|TRIVIA_TYCOON" android ios macos windows linux
# expect 0 in product platform configs
```

Verified after edit: zero matches for those patterns under `android/`, `ios/`, `macos/`, `windows/`, `linux/`, and zero `package:trivia_tycoon` under `lib/` + `test/`.

---

## Next

| Wave | Scope |
|------|--------|
| **F6 + F-docs** | Done — [FLUTTER_RENAME_F6_FDOCS](FLUTTER_RENAME_F6_FDOCS.md) |
| Manual | Local folder rename + GitHub remote rename when ready |
| Local | `flutter pub get` + analyze/test |
