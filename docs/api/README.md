# API Documentation & Integration Guides

This directory contains all API-related documentation including backend contracts, endpoint specifications, and integration patterns.

## 📋 Files

- **BACKEND_API_AUDIT.md** - Complete audit of all backend endpoints with verification status
- **API_ENDPOINTS_VERIFICATION.md** - Endpoint integration checklist and status
- **QUESTIONS_API_IMPLEMENTATION.md** - Phase 1 Questions API detailed implementation guide
- **QUESTIONS_API_QUICK_START.md** - Quick reference for using Questions API in code

## 🔗 Verified Endpoints

### Working ✅
- `GET /api/v1/questions` - Questions API
- `GET /rewards/daily-config` - Daily bonus config
- `GET /account/rewards/status` - Daily bonus status
- `POST /account/rewards/claim` - Claim daily bonus
- `GET /rewards/weekly-schedule` - Weekly rewards
- `POST /rewards/weekly/claim` - Claim weekly reward

### Missing ❌
- Tier progression endpoints (using mock for now)

## 🚀 Quick Reference

### Adding a New API Client
1. Copy pattern from QUESTIONS_API_IMPLEMENTATION.md
2. Use consistent error handling (custom exceptions)
3. Add logging for debugging
4. Document in this directory

### API Client Pattern
```dart
class XyzApiClient {
  final http.Client _httpClient;
  
  XyzApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();
  
  static const String _baseUrl = 'https://api.synaptixplay.com/api/v1';
  
  Future<Model> getXyz() async {
    try {
      LogManager.debug('[XyzApiClient] GET $uri');
      final response = await _httpClient.get(uri);
      // Handle response
    } catch (e) {
      LogManager.error('[XyzApiClient] Error: $e');
      rethrow;
    }
  }
  
  void close() => _httpClient.close();
}
```

## 📚 Models Pattern

All API responses use standard model classes with:
- `factory Constructor.fromJson(Map<String, dynamic> json)` - Deserialization
- `Map<String, dynamic> toJson()` - Serialization
- Helper getters for common operations
- Clear field documentation

## 🛡️ Error Handling

Each API client defines custom exception classes:
- `XyzApiException` - General API errors
- `AlreadyClaimedException` - Duplicate claim errors
- Standard status code handling (401 unauthorized, 404 not found, etc.)

---

**Last Updated:** June 27, 2026
