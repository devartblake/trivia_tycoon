#!/bin/bash
# Flutter Release Build Script
# Builds release apks/ipa/web with automatic validation
#
# Usage:
#   ./scripts/build_release.sh [--target android|ios|web|all] [--validate] [--clean]
#
# Examples:
#   ./scripts/build_release.sh --target android --validate
#   ./scripts/build_release.sh --target ios --clean
#   ./scripts/build_release.sh --target all

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
TARGET="all"
VALIDATE=false
CLEAN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --validate)
      VALIDATE=true
      shift
      ;;
    --clean)
      CLEAN=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate target
if [[ ! "$TARGET" =~ ^(android|ios|web|all)$ ]]; then
  echo -e "${RED}❌ Invalid target: $TARGET${NC}"
  echo "Valid targets: android, ios, web, all"
  exit 1
fi

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Flutter Release Build Script${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Check for required files
if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}❌ pubspec.yaml not found. Please run from project root.${NC}"
  exit 1
fi

# Clean if requested
if [ "$CLEAN" = true ]; then
  echo -e "${YELLOW}🧹 Cleaning build artifacts...${NC}"
  flutter clean
fi

# Pre-build validation (always run)
echo -e "\n${YELLOW}📋 Running pre-build validation...${NC}"
dart scripts/validate_release_build.dart --verbose

# Get Flutter version info
echo -e "\n${BLUE}📌 Build Information:${NC}"
echo "   Flutter version: $(flutter --version | head -1)"
echo "   Dart version: $(dart --version)"
echo "   Target: $TARGET"
echo "   Date: $(date '+%Y-%m-%d %H:%M:%S')"

# Build for specified target(s)
build_android() {
  echo -e "\n${BLUE}📦 Building Android Release (APK)...${NC}"
  flutter build apk --release --target-platform android-arm64,android-arm,android-x86,android-x86_64

  if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    SIZE=$(du -h "build/app/outputs/flutter-apk/app-release.apk" | cut -f1)
    echo -e "${GREEN}✅ Android APK built successfully (${SIZE})${NC}"
    echo "   Location: build/app/outputs/flutter-apk/app-release.apk"

    if [ "$VALIDATE" = true ]; then
      echo -e "\n${YELLOW}🔍 Validating Android APK...${NC}"
      dart scripts/validate_release_build.dart --apk build/app/outputs/flutter-apk/app-release.apk
    fi
  else
    echo -e "${RED}❌ Android APK build failed${NC}"
    exit 1
  fi
}

build_ios() {
  echo -e "\n${BLUE}📦 Building iOS Release...${NC}"
  flutter build ios --release

  if [ -d "build/ios/iphoneos" ]; then
    echo -e "${GREEN}✅ iOS app built successfully${NC}"
    echo "   Location: build/ios/iphoneos"

    if [ "$VALIDATE" = true ]; then
      echo -e "\n${YELLOW}🔍 Validating iOS app...${NC}"
      dart scripts/validate_release_build.dart --target ios
    fi
  else
    echo -e "${RED}❌ iOS build failed${NC}"
    exit 1
  fi
}

build_web() {
  echo -e "\n${BLUE}📦 Building Web Release...${NC}"
  flutter build web --release

  if [ -d "build/web" ]; then
    SIZE=$(du -sh build/web | cut -f1)
    echo -e "${GREEN}✅ Web app built successfully (${SIZE})${NC}"
    echo "   Location: build/web"

    if [ "$VALIDATE" = true ]; then
      echo -e "\n${YELLOW}🔍 Validating Web app...${NC}"
      dart scripts/validate_release_build.dart --target web
    fi
  else
    echo -e "${RED}❌ Web build failed${NC}"
    exit 1
  fi
}

# Execute builds
case $TARGET in
  android)
    build_android
    ;;
  ios)
    build_ios
    ;;
  web)
    build_web
    ;;
  all)
    build_android
    build_ios
    build_web
    ;;
esac

# Final summary
echo -e "\n${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Build Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "\n${YELLOW}📝 Next Steps:${NC}"
echo "   1. Test the build on real devices"
echo "   2. Verify API endpoints are production URLs"
echo "   3. Check logs are minimal in debug console"
echo "   4. Run: flutter run --release (for quick test)"
echo "   5. Submit to app stores"

exit 0
