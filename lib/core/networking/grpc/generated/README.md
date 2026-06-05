# gRPC Generated Code

This directory contains Dart code auto-generated from `protos/mobile.proto`.

**Never edit these files by hand** — they are regenerated whenever the proto changes.

## Generate

```bash
# Install prerequisites (once)
dart pub global activate protoc_plugin

# macOS/Linux
./scripts/generate_proto.sh

# Windows
.\scripts\generate_proto.ps1
```

Requires `protoc` on your PATH:
- macOS: `brew install protobuf`
- Ubuntu/Debian: `apt install protobuf-compiler`
- Windows: `winget install protobuf` or `choco install protoc`

## Files produced

| File | Contents |
|------|----------|
| `mobile.pb.dart` | Message classes (GrpcStartMatchRequest, PlayerAction, MatchEvent, …) |
| `mobile.pbenum.dart` | Enum helpers |
| `mobile.pbgrpc.dart` | MobileMatchServiceClient stub + base class |
| `mobile.pbjson.dart` | JSON serialization helpers |

## Keeping in sync

When `protos/mobile.proto` in the backend changes, copy the updated file to
`trivia_tycoon/protos/mobile.proto` and re-run the generation script.
