#!/usr/bin/env bash
# =============================================================================
# Proto codegen script for synaptix Flutter project.
#
# Generates Dart gRPC stubs from protos/mobile.proto into
# lib/core/networking/grpc/generated/
#
# Prerequisites:
#   1. protoc:         brew install protobuf  |  apt install protobuf-compiler
#   2. Dart plugin:    dart pub global activate protoc_plugin
#   3. PATH must include: $HOME/.pub-cache/bin
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
OUT="$ROOT/lib/core/networking/grpc/generated"

mkdir -p "$OUT"

echo "Generating Dart gRPC stubs from protos/mobile.proto..."
protoc \
  --dart_out="grpc:$OUT" \
  --proto_path="$ROOT/protos" \
  "$ROOT/protos/mobile.proto"

echo "Done. Generated files in $OUT:"
ls "$OUT"
