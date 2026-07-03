# API Documentation & Integration Guides

This directory contains API-related documentation including backend contracts, endpoint verification, and integration patterns.

## Files

- **BACKEND_API_AUDIT.md** - Backend endpoint inventory with July 3, 2026 verification update
- **API_ENDPOINTS_VERIFICATION.md** - Endpoint integration checklist and status
- **QUESTIONS_API_IMPLEMENTATION.md** - Phase 1 Questions API detailed implementation guide
- **QUESTIONS_API_QUICK_START.md** - Quick reference for using Questions API in code

## Verified Endpoints

### Working

- `GET /api/v1/questions` - Questions API
- `GET /api/v1/rewards/daily-config` - Daily bonus config
- `GET /api/v1/account/rewards/status` - Daily bonus status
- `POST /api/v1/account/rewards/claim` - Claim daily bonus
- `GET /api/v1/rewards/weekly-schedule` - Weekly rewards
- `GET /api/v1/rewards/weekly-streak/{userId:guid}` - Weekly streak status
- `POST /api/v1/rewards/weekly/claim` - Claim weekly reward
- `GET /api/v1/progression/tiers` - Tier definitions
- `GET /api/v1/progression/player/{userId:guid}` - Player tier progress
- `POST /api/v1/progression/xp/award` - Award XP

### Current Blockers

- No Phase 2 daily, weekly, or tier/progression endpoint blockers identified as of July 3, 2026.

## Quick Reference

### Adding a New API Client

1. Copy the current Phase 2 client pattern.
2. Inject the shared authenticated HTTP client from providers.
3. Use `EnvConfig.apiV1BaseUrl`; do not hardcode production URLs in providers.
4. Keep custom exceptions and status-code handling close to the client.
5. Add focused contract tests for backend DTO shapes.

### API Client Pattern

```dart
class XyzApiClient {
  final http.Client _httpClient;
  final String _baseUrl;

  XyzApiClient({
    required http.Client httpClient,
    required String baseUrl,
  })  : _httpClient = httpClient,
        _baseUrl = baseUrl;

  Future<Model> getXyz() async {
    try {
      final uri = Uri.parse('$_baseUrl/xyz');
      LogManager.debug('[XyzApiClient] GET $uri');
      final response = await _httpClient.get(uri);
      // Handle response.
    } catch (e) {
      LogManager.error('[XyzApiClient] Error: $e');
      rethrow;
    }
  }
}
```

## Models Pattern

All API responses use model classes with:

- `factory Constructor.fromJson(Map<String, dynamic> json)` - deserialization
- `Map<String, dynamic> toJson()` - serialization
- Field aliases when backend DTO names differ from existing UI model names
- Clear field documentation

## Error Handling

Each API client defines custom exception classes:

- `XyzApiException` - general API errors
- `AlreadyClaimedException` - duplicate claim errors
- Standard status-code handling such as `401`, `404`, and `409`

---

**Last Updated:** July 3, 2026
