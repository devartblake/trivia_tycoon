#!/usr/bin/env bash
# Run Flutter Web on the fixed port allowed by backend CORS policy.
# Usage: ./run_web.sh [edge|chrome]
BROWSER="${1:-edge}"
flutter run -d "$BROWSER" --web-port 63033
