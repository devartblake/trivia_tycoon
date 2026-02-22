# Backend Auth Implementation Checklist

## ✅ What You Already Have

Your `AuthService` already has all the core logic:
- ✅ `RegisterAsync` - Creates new user accounts
- ✅ `LoginAsync` - Authenticates and returns tokens
- ✅ `RefreshAsync` - Refreshes access tokens
- ✅ `LogoutAsync` - Revokes refresh tokens
- ✅ Password hashing with BCrypt
- ✅ JWT token generation
- ✅ Refresh token rotation (revokes old, creates new)

**You just need to wire these up to HTTP endpoints.**

---

## 🔴 Critical Issues to Fix

### 1. Swagger is Broken (5 minutes)
**Problem:** Duplicate route `GET /users/me`
**Fix:** See `SWAGGER_FIX.md` for step-by-step guide

### 2. Missing Signup Endpoint (15 minutes)
**Problem:** No `POST /auth/signup` endpoint
**Fix:** Add the endpoint from `corrected_signup_endpoint.cs`

### 3. Frontend Can't Authenticate (4 hours)
**Problem:** Three duplicate auth systems that don't integrate
**Fix:** See `frontend_backend_auth_analysis.md` for consolidation strategy

---

## 📋 Implementation Steps

### Step 1: Fix Swagger (Do This First!)

```bash
# In Tycoon.Backend.Api, find the duplicate
grep -rn "users/me" . --include="*.cs"

# Delete one of the MapGet("/users/me") calls
# Restart API
docker compose restart backend-api
```

**Verify:** Visit `http://localhost:5000/swagger` - should load now

---

### Step 2: Add Auth Endpoints

Copy the code from **`complete_auth_endpoints.cs`** into your `Program.cs`.

This gives you:
- `POST /auth/signup` - Register new user + auto-login
- `POST /auth/login` - Login with email/password
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - Revoke refresh token

**All endpoints use your existing `AuthService` methods.**

---

### Step 3: Test Backend with Curl

```bash
# 1. Create account
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123",
    "deviceId": "test-device",
    "username": "TestPlayer"
  }'

# Should return:
# {
#   "accessToken": "eyJ...",
#   "refreshToken": "abc...",
#   "expiresIn": 900,
#   "userId": "guid",
#   "user": { ... }
# }

# 2. Login (if signup didn't auto-login)
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123",
    "deviceId": "test-device"
  }'

# 3. Refresh token
curl -X POST http://localhost:5000/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "paste-refresh-token-from-step-1"
  }'

# 4. Logout
curl -X POST http://localhost:5000/auth/logout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer paste-access-token-here" \
  -d '{ "deviceId": "test-device" }'
```

---

### Step 4: Connect Flutter Frontend

#### Option A: Quick Fix (30 minutes)
Update `LoginManager` to use the correct API paths:

```dart
// In lib/core/manager/login_manager.dart
Future<void> signup(SignupData data) async {
  final username = data.additionalSignupData?["Username"] ?? 'Player';
  
  final response = await apiService.signup(
    email: data.name!,
    password: data.password ?? '',
    extra: {
      'username': username,
      if (data.additionalSignupData != null) ...data.additionalSignupData!,
    },
  );
  
  // Parse response and store tokens
  final accessToken = response['accessToken'];
  final refreshToken = response['refreshToken'];
  final userId = response['userId'];
  
  // Store in Hive via AuthTokenStore
  await authTokenStore.save(AuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    userId: userId,
  ));
  
  await secureStorage.setLoggedIn(true);
}
```

#### Option B: Full Refactor (4 hours)
Follow the consolidation plan in `frontend_backend_auth_analysis.md`:
- Pick ONE auth system (recommended: `lib/core/services/`)
- Delete the other two
- Add automatic token refresh
- Wire everything through DI

---

## 🧪 Testing Checklist

Once endpoints are added, test:

- [ ] **POST /auth/signup** returns tokens + user
- [ ] **POST /auth/signup** with duplicate email returns 409
- [ ] **POST /auth/signup** with duplicate username returns 409
- [ ] **POST /auth/login** returns tokens + user
- [ ] **POST /auth/login** with wrong password returns 401
- [ ] **POST /auth/refresh** returns new tokens
- [ ] **POST /auth/refresh** with expired token returns 401
- [ ] **POST /auth/logout** revokes refresh token
- [ ] **Swagger UI** loads without errors
- [ ] **All endpoints** appear in Swagger docs

---

## 📁 Files You Need to Update

### Tycoon.Backend.Api/Program.cs
Add all auth endpoint mappings from `complete_auth_endpoints.cs`

### No Changes Needed To:
- `AuthService.cs` - Already has all the logic
- `IAuthService.cs` - Already has all the methods
- Database - User/RefreshToken tables already exist

---

## ⏱️ Time Estimate

- **Fix Swagger:** 5 minutes
- **Add Signup Endpoint:** 15 minutes
- **Test All Endpoints:** 30 minutes
- **Fix Flutter Frontend:** 30 minutes (quick) OR 4 hours (full refactor)

**Total:** 1.5 hours minimum, 5 hours maximum

---

## 🚨 Common Pitfalls

### 1. "deviceId is required"
Your backend expects `deviceId` in login/signup/refresh.  
Flutter must generate a persistent UUID on first launch.

### 2. "Username already taken"
Your backend uses `handle` field, not `username`.  
The signup endpoint maps `username` → `handle` automatically.

### 3. "Token refresh failed"
Your `RefreshAsync` revokes the old token immediately.  
Flutter must store the NEW refresh token from the response.

### 4. "User account is not active"
Check `user.IsActive` field in database.  
New users might default to `IsActive = false`.

---

## 📞 Need Help?

If you hit any issues:

1. Check Swagger UI for exact request/response formats
2. Check Docker logs: `docker compose logs backend-api --tail=50`
3. Verify database state: `docker compose exec postgres psql -U tycoon_user -d tycoon_db -c "SELECT * FROM users;"`

---

## Next Steps After Auth Works

Once login/signup/refresh/logout all work:

1. Add email verification flow (optional)
2. Add password reset flow
3. Add role-based authorization
4. Add multi-factor authentication (optional)
5. Add social login (Google/Apple) (optional)

But get basic auth working first!
