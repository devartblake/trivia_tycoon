# Flutter Tycoon → Synaptix rename — Waves F1 + F2 + F3

**Date:** 2026-07-13  
**Repo:** `trivia_tycoon` (`C:\Users\lmxbl\StudioProjects\trivia_tycoon`)  
**Companion:** Backend Waves 1–4 in `TycoonTycoon_Backend/docs/status/`

---

## Wave F1 — User-facing copy

| Location | Before | After |
|----------|--------|--------|
| `lib/core/models/tier_definitions.dart` tier 10 name | `TRIVIA TYCOON` | `SYNAPTIX` |
| same — badge | `Trivia Tycoon Crown` | `Synaptix Crown` |
| `lib/screens/login_screen.dart` | ultimate **tycoon** | ultimate **champion** |
| `lib/screens/login_screen_mobile.dart` | same | same |
| `windows/runner/main.cpp` window title | Trivia Tycoon | Synaptix |
| `windows/runner/Runner.rc` ProductName / FileDescription | Trivia Tycoon… | Synaptix… |
| `pubspec.yaml` description | Synaptix Trivia Tycoon… | Synaptix… champion |
| `assets/data/leaderboard/leaderboard.json` titles | Trivia Tycoon | Synaptix |
| `lib/core/repositories/mission_repository.dart` comment | Tycoon.Backend… | Synaptix.Backend… |

**Already Synaptix (no change):** onboarding `Welcome to Synaptix!`, Android/iOS display names, web manifest.

**Left for F5:** `InternalName` / `OriginalFilename` still `trivia_tycoon` / `.exe` (binary identity).

---

## Wave F2 — Toast identifiers

| Before | After |
|--------|--------|
| `tycoonToast` (field / param) | `toast` |
| `tycoonToastPosition` | `toastPosition` |
| `tycoonToastStyle` | `toastStyle` |

**Files:** `synaptix_toast.dart`, `synaptix_toast_route.dart`, `synaptix_toast_helper.dart`, spin-ready toasts, `widget_helper.dart`, `main_menu_screen.dart`.

---

## Wave F3 — gRPC package (align backend Wave 4)

| Item | Before | After |
|------|--------|--------|
| `protos/mobile.proto` | `package tycoon.mobile` | `package synaptix.mobile` (synced from backend) |
| Generated stubs | embed `tycoon.mobile` | `synaptix.mobile` in `lib/core/networking/grpc/generated/mobile.pb*.dart` |

**Note:** `protoc` was not on PATH; stubs were package-string patched to match backend. Prefer re-running when protoc is available:

```powershell
.\scripts\generate_proto.ps1
```

Deploy Flutter with a backend that already serves `synaptix.mobile` (backend Wave 4).

---

## Later waves

| Wave | Scope |
|------|--------|
| **F4+F5** | Done — [FLUTTER_RENAME_F4_F5](FLUTTER_RENAME_F4_F5.md) |
| **F6 + F-docs** | Done — [FLUTTER_RENAME_F6_FDOCS](FLUTTER_RENAME_F6_FDOCS.md) |

---

## Verify

```text
# Expect zero hits in product code:
rg -i "tycoonToast|Trivia Tycoon|TRIVIA TYCOON|ultimate tycoon|tycoon\.mobile" lib test windows
```

Verified after edit: no remaining matches in `lib/`, `test/`, or Windows product title strings for those patterns.
