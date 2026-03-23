# Windows Runner Enhancements

This document describes every customisation made to the `windows/runner`
directory for **Trivia Tycoon** and provides guidance for future maintenance.

---

## Table of Contents

1. [Overview](#1-overview)
2. [File-by-File Reference](#2-file-by-file-reference)
   - [Runner.rc](#21-runnerrc)
   - [runner/CMakeLists.txt](#22-runnercmakeliststxt)
   - [utils.h / utils.cpp](#23-utilsh--utilscpp)
   - [main.cpp](#24-maincpp)
   - [win32_window.cpp](#25-win32_windowcpp)
   - [flutter_window.h / flutter_window.cpp](#26-flutter_windowh--flutter_windowcpp)
   - [runner.exe.manifest](#27-runnerexemanifest)
3. [Architecture Decisions](#3-architecture-decisions)
4. [Future Maintenance](#4-future-maintenance)
5. [Build & Test Guidance](#5-build--test-guidance)

---

## 1. Overview

The `windows/runner` directory contains the native Win32 host application that
embeds the Flutter engine.  The enhancements documented here improve:

| Area | Impact |
|------|--------|
| Branding | Correct company name and file description visible in Windows Explorer |
| Logging | Structured, level-tagged log output useful during development |
| Runtime config | Environment variable and command-line flag support |
| Performance | UI-thread priority boost + resource pre-load |
| Theme | Dynamic light/dark mode switch without restart |
| Window size | Enforced min/max bounds for consistent UX |
| Shortcuts | F1 ➜ Help, bridged to Flutter via platform channel |
| Accessibility | UIA/screen-reader discovery via `WM_GETOBJECT` |
| Build | Debug-only preprocessor flag for conditional code |

---

## 2. File-by-File Reference

### 2.1 `Runner.rc`

**What changed**

| Field | Old value | New value |
|-------|-----------|-----------|
| `CompanyName` | `com.theoreticalmindstech` | `Theoretical Minds Technologies` |
| `FileDescription` | `trivia_tycoon` | `Trivia Tycoon - Interactive Trivia Game` |

**Why**  
Windows Explorer and installer wizards display these values in the file's
*Properties → Details* tab.  The old values were internal identifiers, not
human-readable marketing text.

**Maintenance**  
When the version number changes, Flutter tooling updates the
`FLUTTER_VERSION_*` macros automatically via `CMakeLists.txt`; no manual
edits are needed.

---

### 2.2 `runner/CMakeLists.txt`

**What changed**  
Added a generator-expression compile definition:

```cmake
target_compile_definitions(${BINARY_NAME} PRIVATE
  "$<$<CONFIG:Debug>:TRIVIA_TYCOON_DEBUG_BUILD>"
)
```

**Why**  
The top-level `CMakeLists.txt` already defines `_DEBUG` for Debug builds via
`apply_standard_settings`.  `TRIVIA_TYCOON_DEBUG_BUILD` is an
application-level symbol that lets runner code safely guard debug-only paths
without relying on the CRT-private `_DEBUG` macro.

**Adding new source files**  
Append `.cpp` file names to the `add_executable` block in
`runner/CMakeLists.txt`.  Example:

```cmake
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "my_new_feature.cpp"   # <-- add here
  ...
)
```

---

### 2.3 `utils.h` / `utils.cpp`

#### LogLevel enum

```cpp
enum class LogLevel { kInfo, kWarning, kError, kVerbose };
```

#### LogMessage

```cpp
void LogMessage(LogLevel level, const std::string& message);
```

Writes a prefixed line to both `OutputDebugStringA` (visible in the Visual
Studio Output window or DebugView) and `stdout`.

#### HasCommandLineFlag / GetCommandLineFlagValue

```cpp
bool HasCommandLineFlag(const std::vector<std::string>& args,
                        const std::string& flag);

std::string GetCommandLineFlagValue(const std::vector<std::string>& args,
                                    const std::string& key,
                                    const std::string& default_value = "");
```

Usage example:

```cpp
auto args = GetCommandLineArguments();
if (HasCommandLineFlag(args, "--verbose")) { /* ... */ }
auto mode = GetCommandLineFlagValue(args, "--mode", "release");
```

#### CreateAndAttachConsole improvements

- Checks the `freopen_s` return value and emits a diagnostic via
  `OutputDebugStringA` on failure.
- Reports the Win32 error code when `AllocConsole` fails.

---

### 2.4 `main.cpp`

#### Thread priority

```cpp
::SetThreadPriority(::GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL);
```

Called early in `wWinMain` to reduce frame jitter on busy systems.  Revert
to `THREAD_PRIORITY_NORMAL` if the game logic becomes CPU-intensive and
starves background workers.

#### Environment variable

```cpp
DWORD env_len = ::GetEnvironmentVariableW(L"TRIVIA_TYCOON_ENV", ...);
```

When `TRIVIA_TYCOON_ENV` is set (e.g. `staging`), the value is appended to
the Dart entry-point arguments as `--trivia-env=<value>`.  The Dart side can
read it with:

```dart
// In main.dart
final env = const String.fromEnvironment('trivia-env', defaultValue: 'production');
```

> **Note:** `String.fromEnvironment` reads *compile-time* constants.  To read
> the runtime argument use `PlatformDispatcher.instance.defaultRouteName` or a
> dedicated platform channel.

#### Resource pre-load

Calls `LoadIcon` and `LoadCursor` before window creation to warm the OS
resource cache and marginally improve first-paint time.

#### Window title

Changed from `L"trivia_tycoon"` to `L"Trivia Tycoon"` — the branded display
name shown in the taskbar and title bar.

---

### 2.5 `win32_window.cpp`

#### Dynamic theme (`WM_SETTINGCHANGE`)

```cpp
case WM_SETTINGCHANGE:
  if (lparam != 0 &&
      ::CompareStringOrdinal(..., L"ImmersiveColorSet", ...) == CSTR_EQUAL) {
    UpdateTheme(hwnd);
  }
  return 0;
```

`UpdateTheme` reads `HKCU\…\Themes\Personalize\AppsUseLightTheme` and calls
`DwmSetWindowAttribute(DWMWA_USE_IMMERSIVE_DARK_MODE)`.  The broadcast is
sent by Windows whenever the user changes the colour scheme in Settings.

#### F1 shortcut (`WM_KEYDOWN`)

```cpp
case WM_KEYDOWN:
  if (wparam == VK_F1) {
    ::PostMessage(hwnd, WM_APP, 0, 0);
    return 0;
  }
  break;
```

Using `PostMessage` defers handling to the message loop, avoiding re-entrancy.
`FlutterWindow::MessageHandler` catches `WM_APP` and calls
`SendPlatformMessage`.

To add more shortcuts, extend the `WM_KEYDOWN` handler here and handle the
corresponding `WM_APP + n` values in `flutter_window.cpp`.

#### Accessibility (`WM_GETOBJECT`)

The `WM_GETOBJECT` case is present but does not return early, causing
`DefWindowProc` to handle it.  `DefWindowProc` returns the standard UIA root
element, making the window discoverable by screen readers such as NVDA and
Narrator.

For richer accessibility (e.g. exposing game-state to AT), implement the
[IAccessible2](https://www.ibm.com/able/guidelines/ci162/iAccessible2.html)
(a cross-platform extension to MSAA widely supported on Windows) or the
[UI Automation Provider](https://docs.microsoft.com/en-us/windows/win32/winauto/uiauto-providersoverview)
interfaces and return them from `WM_GETOBJECT`.

---

### 2.6 `flutter_window.h` / `flutter_window.cpp`

#### `<flutter_windows.h>` include

Added to `flutter_window.h` so that `FlutterDesktopGetDpiForHWND` is
available without an extra include in the `.cpp`.

#### Window size enforcement (`WM_GETMINMAXINFO`)

```cpp
static constexpr int kMinWidth  = 800;
static constexpr int kMinHeight = 600;
static constexpr int kMaxWidth  = 3840;
static constexpr int kMaxHeight = 2160;
```

Values are scaled by the monitor DPI at the time the message is received, so
they remain correct across DPI changes.  Adjust the constants to match design
requirements.

#### F1 / Help shortcut relay (`WM_APP`)

```cpp
case WM_APP:
  flutter_controller_->engine()->SendPlatformMessage(
      "com.theoreticalmindstech/shortcuts",
      reinterpret_cast<const uint8_t*>("help"), 4,
      nullptr, nullptr);
  return 0;
```

The Dart side can register a handler with:

```dart
const channel = BasicMessageChannel<String>(
    'com.theoreticalmindstech/shortcuts', StringCodec());
channel.setMessageHandler((msg) async {
  if (msg == 'help') showHelpOverlay();
});
```

---

### 2.7 `runner.exe.manifest`

No changes required.  The manifest already declares:

```xml
<dpiAwareness xmlns="…">PerMonitorV2</dpiAwareness>
```

and lists Windows 10/11 as supported operating systems.

---

## 3. Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| `WM_APP` as shortcut relay message | Avoids coupling Win32Window to FlutterWindow; Win32Window simply posts WM_APP and FlutterWindow decides what to do with it. |
| `LogLevel` in `utils.h` | Keeps log infrastructure centralised and avoids scattered `printf`/`OutputDebugString` calls throughout the codebase. |
| `TRIVIA_TYCOON_DEBUG_BUILD` preprocessor flag | Named symbol is less fragile than checking `_DEBUG` directly; easier to search for in the codebase. |
| `THREAD_PRIORITY_ABOVE_NORMAL` (not `THREAD_PRIORITY_HIGHEST`) | Avoids starving system services while still ensuring Flutter's rasteriser competes well on a normal workload machine. |

---

## 4. Future Maintenance

### Adding a new keyboard shortcut

1. In `win32_window.cpp` → `WM_KEYDOWN`: add a branch for the new virtual
   key and post `WM_APP + 1` (or a higher `WM_APP + n`) to the window.
2. In `flutter_window.cpp` → `WM_APP`: map `wParam` to a string payload and
   call `SendPlatformMessage`.
3. In Dart: extend the `BasicMessageChannel` handler.

### Supporting more environment variables

Add a `GetEnvironmentVariableW` call in `main.cpp` for each new variable and
document it in this file.

### Richer accessibility

Replace the `WM_GETOBJECT` passthrough with a full UI Automation provider
implementation.  See the [MSDN UIA Provider guide](https://docs.microsoft.com/en-us/windows/win32/winauto/uiauto-providersoverview).

### Replacing the application icon

1. Create a new `resources/app_icon.ico` (multi-resolution: 16, 32, 48, 256 px).
2. The `Runner.rc` reference (`IDI_APP_ICON ICON "resources\\app_icon.ico"`) needs
   no changes unless the filename changes.

---

## 5. Build & Test Guidance

### Build

```powershell
flutter config --enable-windows-desktop
flutter pub get
flutter build windows          # Release
flutter build windows --debug  # Debug (sets TRIVIA_TYCOON_DEBUG_BUILD)
```

### Test the enhancements manually

| Feature | How to verify |
|---------|---------------|
| Branding | Right-click `trivia_tycoon.exe` → Properties → Details |
| Dark mode | Toggle *Settings → Personalisation → Colors → Choose your mode* |
| F1 shortcut | Launch app, press F1; observe platform-channel message in Flutter debug console |
| Min window size | Try to resize the window smaller than 800 × 600 |
| `TRIVIA_TYCOON_ENV` | `set TRIVIA_TYCOON_ENV=staging & flutter run -d windows` |
| Log output | Attach WinDbg or DebugView; look for `[trivia_tycoon]` prefixed lines |
