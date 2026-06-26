@echo off
REM Flutter Release Build Script (Windows)
REM Builds release apks/ipa/web with automatic validation
REM
REM Usage:
REM   build_release.bat [--target android|ios|web|all] [--validate] [--clean]
REM
REM Examples:
REM   build_release.bat --target android --validate
REM   build_release.bat --target all --clean

setlocal enabledelayedexpansion

REM Default values
set TARGET=all
set VALIDATE=0
set CLEAN=0

REM Parse arguments
:parse_args
if "%1"=="" goto done_parsing
if "%1"=="--target" (
    set TARGET=%2
    shift
    shift
    goto parse_args
)
if "%1"=="--validate" (
    set VALIDATE=1
    shift
    goto parse_args
)
if "%1"=="--clean" (
    set CLEAN=1
    shift
    goto parse_args
)
shift
goto parse_args

:done_parsing
REM Validate target
if not "%TARGET%"=="android" if not "%TARGET%"=="ios" if not "%TARGET%"=="web" if not "%TARGET%"=="all" (
    echo.
    echo [ERROR] Invalid target: %TARGET%
    echo Valid targets: android, ios, web, all
    exit /b 1
)

echo.
echo ════════════════════════════════════════════════════════════
echo 🚀 Flutter Release Build Script
echo ════════════════════════════════════════════════════════════

REM Check for required files
if not exist "pubspec.yaml" (
    echo [ERROR] pubspec.yaml not found. Please run from project root.
    exit /b 1
)

REM Clean if requested
if %CLEAN%==1 (
    echo.
    echo 🧹 Cleaning build artifacts...
    call flutter clean
    if errorlevel 1 exit /b 1
)

REM Pre-build validation (always run)
echo.
echo 📋 Running pre-build validation...
call dart scripts/validate_release_build.dart --verbose
if errorlevel 1 exit /b 1

REM Get Flutter version info
echo.
echo 📌 Build Information:
for /f "tokens=*" %%i in ('flutter --version') do set FLUTTER_VERSION=%%i & goto got_flutter
:got_flutter
echo    Flutter version: %FLUTTER_VERSION%

for /f "tokens=*" %%i in ('dart --version') do echo    Dart version: %%i

echo    Target: %TARGET%
for /f "tokens=*" %%i in ('powershell get-date -format "yyyy-MM-dd HH:mm:ss"') do echo    Date: %%i

REM Build for specified target(s)
if "%TARGET%"=="android" (
    call :build_android
    if errorlevel 1 exit /b 1
)

if "%TARGET%"=="ios" (
    call :build_ios
    if errorlevel 1 exit /b 1
)

if "%TARGET%"=="web" (
    call :build_web
    if errorlevel 1 exit /b 1
)

if "%TARGET%"=="all" (
    call :build_android
    if errorlevel 1 exit /b 1
    call :build_ios
    if errorlevel 1 exit /b 1
    call :build_web
    if errorlevel 1 exit /b 1
)

echo.
echo ════════════════════════════════════════════════════════════
echo ✅ Build Complete!
echo ════════════════════════════════════════════════════════════
echo.
echo 📝 Next Steps:
echo    1. Test the build on real devices
echo    2. Verify API endpoints are production URLs
echo    3. Check logs are minimal in debug console
echo    4. Run: flutter run --release (for quick test)
echo    5. Submit to app stores

exit /b 0

:build_android
echo.
echo 📦 Building Android Release (APK)...
call flutter build apk --release --target-platform android-arm64,android-arm,android-x86,android-x86_64
if errorlevel 1 (
    echo [ERROR] Android APK build failed
    exit /b 1
)

if exist "build\app\outputs\flutter-apk\app-release.apk" (
    for %%f in (build\app\outputs\flutter-apk\app-release.apk) do set SIZE=%%~zf
    setlocal enabledelayedexpansion
    set /a SIZE_KB=!SIZE! / 1024
    echo ✅ Android APK built successfully (!SIZE_KB! KB^)
    echo    Location: build\app\outputs\flutter-apk\app-release.apk

    if %VALIDATE%==1 (
        echo.
        echo 🔍 Validating Android APK...
        call dart scripts/validate_release_build.dart --apk build\app\outputs\flutter-apk\app-release.apk
        if errorlevel 1 exit /b 1
    )
) else (
    echo [ERROR] Android APK not found after build
    exit /b 1
)
exit /b 0

:build_ios
echo.
echo 📦 Building iOS Release...
call flutter build ios --release
if errorlevel 1 (
    echo [ERROR] iOS build failed
    exit /b 1
)

if exist "build\ios\iphoneos" (
    echo ✅ iOS app built successfully
    echo    Location: build\ios\iphoneos

    if %VALIDATE%==1 (
        echo.
        echo 🔍 Validating iOS app...
        call dart scripts/validate_release_build.dart --target ios
        if errorlevel 1 exit /b 1
    )
) else (
    echo [ERROR] iOS app not found after build
    exit /b 1
)
exit /b 0

:build_web
echo.
echo 📦 Building Web Release...
call flutter build web --release
if errorlevel 1 (
    echo [ERROR] Web build failed
    exit /b 1
)

if exist "build\web" (
    echo ✅ Web app built successfully
    echo    Location: build\web

    if %VALIDATE%==1 (
        echo.
        echo 🔍 Validating Web app...
        call dart scripts/validate_release_build.dart --target web
        if errorlevel 1 exit /b 1
    )
) else (
    echo [ERROR] Web app not found after build
    exit /b 1
)
exit /b 0
