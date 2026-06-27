# Questions API - Quick Start Guide

## 🚀 TL;DR

Questions now load from API with automatic fallback to assets. No code changes needed to use it.

---

## 📌 What Changed

### Before
```dart
// Questions loaded only from assets
final questions = await loader.loadDataset('Science');
// ↓ Loads from: assets/data/questions/science.json
```

### After
```dart
// Questions try API first, fallback to assets
final questions = await loader.loadDataset('Science');
// ↓ Tries: GET /api/v1/questions?category=Science&count=100
// ↓ Fails? Falls back to: assets/data/questions/science.json
```

**Key Point:** Zero code changes needed - it's backward compatible!

---

## 🔧 How to Use

### Load Questions by Category
```dart
// In your quiz screen
final questions = await questionLoader.loadDataset('Science');
// Returns: List<QuestionModel>
```

### Load Multiple Categories
```dart
// For multiplayer or challenge modes
final questions = await questionLoader.getQuestionsForCategories([
  'Science',
  'History',
  'Geography',
]);
// Returns: Map<String, List<QuestionModel>>
```

### Load for Multiplayer
```dart
// Use QuestionApiClient directly
final questions = await apiClient.getMultiplayerQuestions(
  matchId: 'match-123',
  categories: ['Science', 'History'],
  count: 20,
);
```

### Preload on App Startup
```dart
// Already done in app_init.dart, but if you want manual control:
await questionLoader.preloadTopCategories(count: 10);
```

---

## 🎯 API Endpoints

### Get Questions
```
GET /api/v1/questions
  ?category=Science
  &count=20
  &difficulty=medium
```

**Parameters:**
- `category` (required): Category ID or name
- `count` (optional): Number of questions (default: 20)
- `difficulty` (optional): easy, medium, hard
- `mode` (optional): Game mode

**Response:**
```json
[
  {
    "id": "q1",
    "question": "What is H2O?",
    "options": ["Water", "Hydrogen", "Oxygen", "Salt"],
    "correctAnswer": 0,
    "category": "science",
    "difficulty": "medium"
  }
]
```

### Get Multiplayer Questions
```
GET /api/v1/questions/multiplayer
  ?matchId=match-123
  &categories=Science,History
  &count=20
```

---

## 💾 Caching

| Data | TTL | When to Refetch |
|------|-----|-----------------|
| Questions | 24 hours | Next day or manual refresh |
| Cache | Auto-validated | After TTL expires |

**How it works:**
1. Request comes in
2. Check: Is it cached & valid?
   - ✅ Yes → Return cached (instant)
   - ❌ No → Fetch from API
3. API fails? → Fall back to assets

---

## 🔄 Fallback Flow

```
Request Questions
    ↓
Check Cache
    ↓ Valid? ──→ Return (Fast) ✅
    ↓
Try API
    ↓ Success? ──→ Cache & Return ✅
    ↓
Fallback to Assets
    ↓ Success? ──→ Return ✅
    ↓
Return Empty List (Graceful Failure)
```

---

## 🐛 Debugging

### Enable Logging
```dart
// Already enabled, check LogManager output
[QuestionLoader] Attempting to fetch Science from API
[QuestionLoader] Successfully loaded Science from API (45 questions)
```

### Check Cache Status
```dart
// Cache is internal, but you can see it working via logs:
// First load: "Attempting to fetch from API"
// Second load (same session): "Cache valid" (no API call)
```

### Force Fresh Data
```dart
// Clear cache and reload
// TODO: Add cache clearing method when needed
```

---

## ⚠️ Error Handling

### API Unavailable
```
✅ Automatically falls back to assets
✅ App continues working
✅ User sees questions (from cache/assets)
❌ Questions might not be latest
```

### Network Timeout
```
✅ Fallback triggers after timeout
✅ Questions still load from assets
⏱️ Small delay before showing questions
```

### Category Not Found
```
✅ Returns empty list (doesn't crash)
✅ UI should handle empty case
❌ User sees "No questions available"
```

---

## 📊 Performance

| Scenario | Time | Source |
|----------|------|--------|
| First load (API) | ~500ms | API |
| Cached load | ~5ms | Memory |
| Offline load | ~50ms | Assets |
| Timeout fallback | ~5s + fallback | Assets |

---

## ✅ Testing Checklist

Run through these to verify it's working:

- [ ] App starts (check logs for preload message)
- [ ] Select a category (questions load)
- [ ] Check Network tab: Does API get called?
- [ ] Offline mode: Disable network, load category (should work)
- [ ] Second load of same category: Should be instant (cached)
- [ ] Different category: Should show "Attempting to fetch"
- [ ] Check browser cache: Questions persist across sessions

---

## 🚨 Known Limitations

1. **Cache not persistent**: Lost when app restarts
   - Will add persistent caching in Phase 2

2. **No rate limiting**: Backend should implement
   - Prevent abuse of question fetching

3. **Manual cache clear**: Not yet implemented
   - User must restart app to get fresh questions

4. **No offline queue**: Failed API calls don't retry
   - Just uses cached/asset data instead

---

## 🔐 Security

- ✅ No credentials in questions
- ✅ No sensitive data exposed
- ✅ API requires authentication (if implemented)
- ✅ HTTPS only (uses synaptixplay.com domain)

---

## 📚 Related Files

| File | Purpose |
|------|---------|
| `question_api_client.dart` | API client |
| `question_loader_service.dart` | Loader service |
| `app_init.dart` | Preload integration |
| `QUESTIONS_API_IMPLEMENTATION.md` | Full documentation |

---

## 🎓 Next Steps

### Phase 2 (Week 2)
- Implement Tier System API
- Implement Daily Bonus API
- Implement Weekly Rewards API

### Phase 3 (Week 3)
- Implement Missions API
- Implement Challenges API
- Implement Categories API

### Phase 4 (Week 4)
- Implement Game Config API
- Implement Store Items API

---

## 💬 Questions?

Refer to:
1. `QUESTIONS_API_IMPLEMENTATION.md` for detailed docs
2. `question_api_client.dart` for code comments
3. Logs for debugging (check console/DevTools)

---

**Status:** ✅ Ready to Use  
**Last Updated:** June 26, 2026  
**Next Review:** After Phase 2 completion
