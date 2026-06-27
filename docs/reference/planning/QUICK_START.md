# Quick Implementation Guide

## What You Need to Do

### 1. Replace AuthEndpoints.cs (5 minutes)
**Location:** `Tycoon.Backend.Api/Features/Auth/AuthEndpoints.cs`

Replace your current file with the new `AuthEndpoints.cs` that includes the `HandleSignup` method.

**What Changed:**
- ✅ Added `authGroup.MapPost("/signup", HandleSignup);`
- ✅ Added complete `HandleSignup` method that registers + auto-logs in
- ✅ Kept all existing endpoints unchanged (`/register`, `/login`, `/refresh`, `/logout`)

---

### 2. Update Your DTOs (2 minutes)
**Location:** `Tycoon.Shared.Contracts/Dtos/` (or wherever your DTOs live)

Add these two new records to your existing DTOs file:
```csharp
public record SignupRequest(
    string Email,
    string Password,
    string DeviceId,
    string? Username = null,
    string? Handle = null,
    string? Country = null
);

public record SignupResponse(
    string AccessToken,
    string RefreshToken,
    int ExpiresIn,
    string UserId,
    UserDto User
);
```

**Or:** Just copy the entire `AuthDtos.cs` file I provided (it has all your existing DTOs plus the new ones).

---

### 3. Test It (10 minutes)
Follow the curl commands in `SIGNUP_TESTING_GUIDE.md`:

```bash
# 1. Restart API
docker compose restart backend-api

# 2. Test signup
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123",
    "deviceId": "test-device",
    "username": "TestUser"
  }'

# Should return tokens immediately!
```

---

### 4. Fix Swagger (if still broken)
If Swagger still shows the duplicate `GET /users/me` error, follow `SWAGGER_FIX.md` to find and delete it.

---

## Files Provided

### ✅ AuthEndpoints.cs
- Complete replacement for your existing file
- Adds `/auth/signup` endpoint
- Keeps all existing endpoints working

### ✅ AuthDtos.cs
- All your existing DTOs plus `SignupRequest` and `SignupResponse`
- Copy the two new records to your existing DTOs file

### ✅ SIGNUP_TESTING_GUIDE.md
- Curl commands for every test case
- Swagger UI testing instructions
- Complete flow testing (signup → use token → refresh → logout)
- Database verification queries
- Flutter integration example

### ✅ IMPLEMENTATION_CHECKLIST.md
- Overall roadmap for backend + frontend integration
- Time estimates
- What you already have vs what's missing

---

## Why This Approach?

Your existing code structure is clean:
- ✅ Endpoints in `AuthEndpoints.cs`
- ✅ DTOs in shared contracts
- ✅ Business logic in `AuthService`

I'm following your pattern instead of putting code in `Program.cs`.

---

## What Happens When Someone Signs Up?

### Backend Flow:
1. Validate email, password, deviceId
2. Call `authService.RegisterAsync()` → creates User record
3. Immediately call `authService.LoginAsync()` → creates RefreshToken record + generates JWT
4. Return tokens + user info to Flutter

### Frontend Flow (Flutter):
1. User fills signup form
2. App calls `POST /auth/signup`
3. Gets back: `{ accessToken, refreshToken, userId, user }`
4. Stores tokens in Hive
5. User is logged in — redirect to home screen

**One API call instead of two!**

---

## Differences from /auth/register

| Feature | /auth/register | /auth/signup |
|---------|---------------|--------------|
| Creates User | ✅ | ✅ |
| Returns Tokens | ❌ | ✅ |
| Auto-Login | ❌ | ✅ |
| Response Code | 201 Created | 200 OK |
| Use Case | Web (separate register/login) | Mobile (one-step signup) |

**Keep both!** They serve different purposes.

---

## Need Help?

If anything doesn't work:

1. Check backend logs: `docker compose logs backend-api --tail=50`
2. Check database: `docker compose exec postgres psql -U tycoon_user -d tycoon_db`
3. Verify Swagger: `http://localhost:5000/swagger`
4. Review the testing guide for specific error cases

---

## Next: Frontend Integration

Once the backend is working, update your Flutter `LoginManager`:

```dart
Future<void> signup(SignupData data) async {
  final deviceId = await deviceIdService.getOrCreate();
  
  final response = await http.post(
    Uri.parse('$baseUrl/auth/signup'),
    body: jsonEncode({
      'email': data.name,
      'password': data.password,
      'deviceId': deviceId,
      'username': data.additionalSignupData?['Username'] ?? 'Player',
    }),
  );
  
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    await authTokenStore.save(AuthSession(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      userId: json['userId'],
    ));
  }
}
```

Then follow `frontend_backend_auth_analysis.md` to consolidate your three auth systems into one.
