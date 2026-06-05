# =============================================================================
# Proto codegen script for trivia_tycoon Flutter project (PowerShell).
#
# Generates Dart gRPC stubs from protos/mobile.proto into
# lib/core/networking/grpc/generated/
#
# Prerequisites:
#   1. protoc:        winget install protobuf  OR  choco install protoc
#   2. Dart plugin:   dart pub global activate protoc_plugin
#   3. PATH must include: %APPDATA%\Pub\Cache\bin
# =============================================================================

$Root = Split-Path -Parent $PSScriptRoot
$Out  = Join-Path $Root "lib\core\networking\grpc\generated"

New-Item -ItemType Directory -Force -Path $Out | Out-Null

Write-Host "Generating Dart gRPC stubs from protos/mobile.proto..."
& protoc `
    "--dart_out=grpc:$Out" `
    "--proto_path=$Root\protos" `
    "$Root\protos\mobile.proto"

Write-Host "Done. Generated files in $Out:"
Get-ChildItem $Out | Select-Object -ExpandProperty Name
