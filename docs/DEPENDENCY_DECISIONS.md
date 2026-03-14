# Dependency Decisions

> Last reviewed: 2026-03-14 (Phase 4 — Dependency Audit)
>
> Direct dependency count at audit: **57** (down from **62**, 5 removed)

This document records the reasoning behind every direct dependency in
`pubspec.yaml`.  Update it whenever a package is added, removed, or its
role changes.

---

## Removed in Phase 4

| Package | Version | Reason for removal |
|---------|---------|-------------------|
| `rive` | ^0.13.20 | Zero imports across `lib/`. No Rive animations are used. |
| `animated_text_kit` | ^4.2.3 | Zero imports across `lib/`. No typewriter / animated text is used. |
| `audio_service` | ^0.18.17 | Zero imports across `lib/`. Background-audio OS integration is not yet implemented; add back when background playback is required. |
| `http_cache_hive_store` | ^5.0.2 | Zero imports across `lib/`. HTTP-level caching is handled by `dio_cache_interceptor_hive_store` via `ApiService`. |
| `image_editor` | ^1.6.0 | Zero imports across `lib/`. Image editing is not yet implemented; add back when crop/filter features land. |

---

## HTTP Clients — Dual Strategy (Intentional)

Two HTTP packages coexist with distinct roles:

### `http` ^1.3.0 — Simple public-endpoint helper
Used in 14+ files for straightforward GET/POST calls to public or
lightly-authenticated endpoints (question loading, analytics, avatar
packages, etc.).  These files predated `ApiService` and make no use of
interceptors, caching, or token refresh.

**New code should prefer `ApiService`** (see below) for any call that
requires auth, caching, or retry logic.

### `dio` ^5.8.0+1 — Full-featured API engine (via `ApiService`)
`lib/core/services/api_service.dart` is built entirely on Dio and
provides:
- `DioInterceptor`-based token refresh (automatic 401 retry)
- `DioCacheInterceptor` + Hive cache store (7-day stale policy)
- Configurable connect/receive/send timeouts (fail-fast in dev)
- Typed error extraction (`ApiRequestException`)
- Paginated envelope parsing (`ApiPageEnvelope<T>`)

Migrating all 14 `http` call sites to Dio/`ApiService` is deferred
until a broader networking refactor sprint.

**Supporting packages kept for Dio:**

| Package | Role |
|---------|------|
| `dio_cache_interceptor` ^3.5.1 | Cache interceptor wired into `ApiService` |
| `dio_cache_interceptor_hive_store` ^4.0.0 | Hive-backed cache store for the interceptor |

---

## Audio — Intentional Dual Library

Two audio libraries coexist because they serve different use-cases:

### `just_audio` ^0.9.46 — Background music streaming
Used in 5 files.  Provides the streaming music player (`AudioPlayer`)
with loop modes, seek, volume control, and codec support across
platforms.  Used in `SoundManager` for background tracks and in several
screen-level audio components.

### `flutter_soloud` ^3.0.2 — Low-latency game SFX
Used in 2 files (`AudioController`, `SoundManager`).  SoLoud is a
C++-backed audio engine that achieves <5 ms playback latency — essential
for responsive game sound effects (button clicks, wheel ticks, spin
sequences, win sounds).  `just_audio` streams audio through the OS
pipeline and cannot match this latency for short SFX.

**Consolidation is not recommended**: removing `flutter_soloud` and
routing SFX through `just_audio` would introduce perceptible input lag
on game interactions.

---

## All Retained Packages

| Package | Reason |
|---------|--------|
| `cupertino_icons` | iOS-style icons used in UI |
| `vector_math` | 3D math used by `flutter_3d_controller`; overridden to `^2.1.8` to satisfy transitive constraint |
| `intl` | Date/number formatting throughout the app |
| `encrypt` | AES-256 encryption in `EncryptionManagerScreen` and token storage |
| `http` | Simple HTTP calls; see above |
| `path` | File path manipulation on desktop/mobile |
| `dio` | Full API engine; see above |
| `crypto` | SHA hashing for cache keys and token fingerprinting |
| `hive` | Primary local key-value store (settings, tokens, progress) |
| `quiver` | Used in 2 files for `Optional` / collection utilities |
| `shimmer` | Loading skeleton animations (9 usages) |
| `logging` | Dart `Logger` used throughout the codebase for structured logs |
| `go_router` | Declarative routing; deep link and navigation guard support |
| `url_launcher` | Opens external URLs (browser, email) |
| `hive_flutter` | Flutter adapter for Hive (box lifecycle, widget rebuilds) |
| `image_picker` | Avatar upload; camera/gallery picker |
| `flutter_svg` | SVG rendering for category icons and UI assets |
| `flutter_soloud` | Low-latency SFX engine; see above |
| `flutter_dotenv` | Loads `.env` for environment configuration |
| `flutter_animate` | Declarative animation DSL used across screens |
| `flutter_riverpod` | Primary state management |
| `flutter_3d_controller` | 3D model viewer for avatar/store screens |
| `flutter_secure_storage` | Encrypted keychain storage for auth tokens |
| `font_awesome_flutter` | FontAwesome icons (social, badges) |
| `dio_cache_interceptor` | See HTTP section |
| `phone_numbers_parser` | Used in registration for phone validation |
| `intl_phone_number_input` | Phone number input field widget with country picker |
| `another_transformer_page_view` | Animated page transitions in onboarding/quiz flows |
| `dio_cache_interceptor_hive_store` | See HTTP section |
| `textstyle_extensions` | Fluent TextStyle API used in theme components |
| `file_picker` | Document/file selection for admin question import |
| `permission_handler` | Runtime permission requests (camera, notifications, storage) |
| `awesome_notifications` | Rich local notifications with actions and badges |
| `just_audio` | Background music; see above |
| `sign_in_button` | Pre-styled OAuth sign-in buttons (Google, Apple, etc.) |
| `image` | Image byte manipulation for avatar processing |
| `fernet` | Fernet symmetric encryption in `EncryptionManagerScreen` (admin tool) |
| `camera` | Camera preview for avatar capture |
| `fl_chart` | Charts in stats/leaderboard screens |
| `logger` | Pretty-printed log output in development (wraps `logging`) |
| `connectivity_plus` | Network state monitoring for offline fallback |
| `video_player` | Video playback in promotional/tutorial screens |
| `chewie` | Flutter UI controls wrapping `video_player` |
| `cached_network_image` | Networked image loading with disk cache |
| `web_socket_channel` | WebSocket client for real-time multiplayer and leaderboard |
| `share_plus` | Native share sheet for sharing scores and referral codes |
| `equatable` | Value equality for state objects (Riverpod, models) |
| `path_provider` | Platform paths for Hive stores and cache directories |
| `in_app_purchase` | IAP for gem/coin packs and premium features |
| `qr_flutter` | QR code generation for referral and challenge links |
| `archive` | ZIP archive handling for bulk question import/export |
| `uuid` | UUID v4 generation for entity IDs, session tokens |

---

## Dev Dependencies

| Package | Reason |
|---------|--------|
| `flutter_test` | Flutter widget and unit testing framework |
| `build_runner` | Code generation runner for Hive type adapters |
| `hive_generator` | Generates `TypeAdapter` classes from Hive annotations |
| `in_app_purchase_platform_interface` | Pinned to satisfy a transitive version conflict with `in_app_purchase`; review when upgrading `in_app_purchase` to a new major version |

---

## Dependency Overrides

| Package | Override | Reason |
|---------|---------|--------|
| `vector_math` | ^2.1.8 | `flutter_3d_controller` requires `>=2.1.8`; the direct spec uses `^2.1.4` |
| `flutter_lints` | ^5.0.0 | Align lints version across the transitive graph |
