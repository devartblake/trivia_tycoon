# Changelog

All notable changes to **Trivia Tycoon** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added – `windows/runner` enhancements

#### 1. Branding Customizations (`Runner.rc`)
- Updated `CompanyName` from the internal bundle ID to the full human-readable
  name **"Theoretical Minds Technologies"**.
- Updated `FileDescription` to **"Trivia Tycoon - Interactive Trivia Game"**
  to give Windows users a clear description in Explorer properties.
- All other version fields (`LegalCopyright`, `ProductName`, `OriginalFilename`)
  were already correct and are left unchanged.

#### 2. Build Configuration (`runner/CMakeLists.txt`)
- Added a `TRIVIA_TYCOON_DEBUG_BUILD` preprocessor definition that is set only
  for `Debug` configurations, enabling conditional debug code paths in C++.
- Source file list is clearly delimited to make it easy to append new `.cpp`
  files in future feature work.

#### 3. Runtime Configuration (`utils.h` / `utils.cpp`)
- Introduced `LogLevel` enum (`kInfo`, `kWarning`, `kError`, `kVerbose`) for
  structured console output.
- Added `LogMessage(LogLevel, const std::string&)` helper that prefixes each
  message with the application name and log level and forwards it to both
  `OutputDebugStringA` and `stdout`.
- `CreateAndAttachConsole` now checks the return value of `freopen_s` and
  emits verbose `OutputDebugStringA` diagnostics on failure, as well as
  reporting the Win32 error code when `AllocConsole` fails.
- Added `HasCommandLineFlag(args, flag)` – returns `true` when an exact flag
  (e.g. `--verbose`) is present in the argument list.
- Added `GetCommandLineFlagValue(args, key, default)` – extracts the value from
  a `--key=value` argument pair, returning `default` when the key is absent.

#### 4. Environment Variable Support (`main.cpp`)
- Reads the `TRIVIA_TYCOON_ENV` environment variable at startup.  When set,
  its value is forwarded to the Dart entry-point as `--trivia-env=<value>`,
  allowing runtime environment switching (e.g. `staging`, `production`).

#### 5. Performance Optimizations (`main.cpp`)
- Calls `SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL)`
  on the UI thread at startup to deliver smoother Flutter animations.
- Pre-loads common OS resources (`IDI_APPLICATION`, `IDC_ARROW`) before the
  window is created, priming the OS resource cache and reducing first-paint
  latency.

#### 6. DPI and Theme Awareness (`win32_window.cpp`)
- `runner.exe.manifest` already declared `PerMonitorV2` DPI awareness; no
  change required.
- Added handling of `WM_SETTINGCHANGE` to call `UpdateTheme()` whenever the
  system broadcasts an `ImmersiveColorSet` notification, ensuring the window
  frame switches between light and dark mode without requiring a restart.

#### 7. Keyboard Shortcuts (`win32_window.cpp`)
- Added `WM_KEYDOWN` handler: pressing **F1** posts `WM_APP` to the window,
  which is caught by `FlutterWindow::MessageHandler` and forwarded to the
  Flutter engine as a platform message on channel
  `com.theoreticalmindstech/shortcuts` with payload `"help"`.

#### 8. Accessibility Support (`win32_window.cpp`)
- Added a `WM_GETOBJECT` case so that the window is visible to UI Automation
  and screen-reader tools.  The default `DefWindowProc` response provides the
  standard UIA root element.

#### 9. Flutter-Specific Optimizations (`flutter_window.cpp` / `flutter_window.h`)
- Enforces minimum window size of **800 × 600** logical pixels and a maximum
  of **3840 × 2160** (4K), both scaled by the current monitor DPI.
  Implemented via `WM_GETMINMAXINFO` using `FlutterDesktopGetDpiForHWND`.
- Added `WM_APP` handler in `FlutterWindow::MessageHandler` to relay the F1
  shortcut to the Dart layer via `SendPlatformMessage`.
- Added `<flutter_windows.h>` include to `flutter_window.h` to expose
  `FlutterDesktopGetDpiForHWND`.

#### 10. Window Title
- Changed the Win32 window title from the internal package name `trivia_tycoon`
  to the branded title **"Trivia Tycoon"** in `main.cpp`.
