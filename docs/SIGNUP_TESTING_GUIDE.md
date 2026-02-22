# Testing the New /auth/signup Endpoint

## What Changed

### Before:
- `POST /auth/register` - Creates account, returns 201 (no tokens)
- `POST /auth/login` - Logs in, returns tokens

**Problem:** Mobile apps had to make 2 calls for signup flow

### After:
- `POST /auth/register` - Still exists (for web flows that need separate register/login)
- `POST /auth/signup` - **NEW**: Creates account + auto-login, returns tokens immediately
- `POST /auth/login` - Unchanged

**Benefit:** Mobile apps can signup in one call

---

## Testing with Curl

### 1. Test Successful Signup

```bash
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newplayer@example.com",
    "password": "SecurePass123",
    "deviceId": "test-device-001",
    "username": "CoolPlayer"
  }'
```

**Expected Response (200 OK):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "base64-encoded-random-token...",
  "expiresIn": 900,
  "userId": "guid-string-here",
  "user": {
    "id": "guid-here",
    "handle": "CoolPlayer",
    "email": "newplayer@example.com",
    "country": null,
    "tier": "Bronze",
    "mmr": 1000
  }
}
```

### 2. Test Duplicate Email (Conflict)

```bash
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newplayer@example.com",
    "password": "DifferentPass456",
    "deviceId": "test-device-002",
    "username": "AnotherPlayer"
  }'
```

**Expected Response (409 Conflict):**
```json
{
  "error": "email_already_exists",
  "message": "This email is already registered"
}
```

### 3. Test Duplicate Username (Conflict)

```bash
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "different@example.com",
    "password": "SecurePass123",
    "deviceId": "test-device-003",
    "username": "CoolPlayer"
  }'
```

**Expected Response (409 Conflict):**
```json
{
  "error": "username_taken",
  "message": "This username is already taken"
}
```

### 4. Test Missing Required Fields

```bash
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "short"
  }'
```

**Expected Response (400 Bad Request):**
```json
{
  "error": "DeviceId is required"
}
```

Or if password is too short:
```json
{
  "error": "Password must be at least 8 characters"
}
```

### 5. Test Signup Without Username (Uses Email Prefix)

```bash
curl -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "player@example.com",
    "password": "SecurePass123",
    "deviceId": "test-device-004"
  }'
```

**Expected Response (200 OK):**
```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "expiresIn": 900,
  "userId": "guid",
  "user": {
    "handle": "player",  // ← Extracted from email
    "email": "player@example.com",
    ...
  }
}
```

---

## Testing with Swagger UI

1. Start your backend: `docker compose up backend-api`
2. Navigate to: `http://localhost:5000/swagger`
3. Find the **Authentication** section
4. Click **POST /auth/signup**
5. Click **Try it out**
6. Fill in the request body:
   ```json
   {
     "email": "swagger@test.com",
     "password": "TestPass123",
     "deviceId": "swagger-device",
     "username": "SwaggerUser"
   }
   ```
7. Click **Execute**
8. Check response (should be 200 with tokens)

---

## Testing the Complete Flow

### Step 1: Signup
```bash
RESPONSE=$(curl -s -X POST http://localhost:5000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "flowtest@example.com",
    "password": "TestFlow123",
    "deviceId": "flow-device",
    "username": "FlowUser"
  }')

echo $RESPONSE | jq .
```

### Step 2: Extract Tokens
```bash
ACCESS_TOKEN=$(echo $RESPONSE | jq -r .accessToken)
REFRESH_TOKEN=$(echo $RESPONSE | jq -r .refreshToken)

echo "Access Token: $ACCESS_TOKEN"
echo "Refresh Token: $REFRESH_TOKEN"
```

### Step 3: Use Access Token (Protected Endpoint)
```bash
curl -X GET http://localhost:5000/users/me \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

**Expected:** Your user details

### Step 4: Refresh Token
```bash
NEW_RESPONSE=$(curl -s -X POST http://localhost:5000/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}")

echo $NEW_RESPONSE | jq .
```

**Expected:** New access token + new refresh token

### Step 5: Logout
```bash
curl -X POST http://localhost:5000/auth/logout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{"deviceId": "flow-device"}'
```

**Expected:** 204 No Content

### Step 6: Try Using Old Refresh Token (Should Fail)
```bash
curl -X POST http://localhost:5000/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}"
```

**Expected:** 401 Unauthorized (token was revoked)

---

## Common Issues & Solutions

### Issue 1: "Email is already registered"
**Cause:** User already exists in database  
**Solution:** Use a different email or delete the user from database:
```sql
DELETE FROM users WHERE email = 'test@example.com';
DELETE FROM refresh_tokens WHERE user_id = 'guid-here';
```

### Issue 2: "Username already taken"
**Cause:** Handle/username is not unique  
**Solution:** Use a different username or check existing handles:
```sql
SELECT id, handle, email FROM users WHERE handle = 'CoolPlayer';
```

### Issue 3: 500 Internal Server Error
**Cause:** Usually database connection issue or missing migration  
**Solution:** Check backend logs:
```bash
docker compose logs backend-api --tail=50
```

### Issue 4: DeviceId Required
**Cause:** Missing deviceId in request  
**Solution:** Always send a unique, persistent device ID from Flutter:
```dart
// In Flutter, generate once and store
final deviceId = await getOrCreateDeviceId();
```

---

## Integration with Flutter

Your Flutter frontend should now work with this endpoint:

```dart
// In lib/core/manager/login_manager.dart
Future<void> signup(SignupData data) async {
  final username = data.additionalSignupData?["Username"] ?? 'Player';
  
  // Call the new /auth/signup endpoint
  final response = await apiService.signup(
    email: data.name!,
    password: data.password ?? '',
    deviceId: await deviceIdService.getOrCreate(),
    extra: {'username': username},
  );
  
  // Response contains tokens immediately
  final accessToken = response['accessToken'];
  final refreshToken = response['refreshToken'];
  final userId = response['userId'];
  
  // Store tokens in Hive
  await authTokenStore.save(AuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    userId: userId,
  ));
  
  await secureStorage.setLoggedIn(true);
}
```

---

## Database Verification

After signup, verify the user was created:

```bash
docker compose exec postgres psql -U tycoon_user -d tycoon_db
```

```sql
-- Check user was created
SELECT id, email, handle, created_at_utc, is_active 
FROM users 
WHERE email = 'newplayer@example.com';

-- Check refresh token was created
SELECT id, user_id, device_id, expires_at, is_revoked
FROM refresh_tokens
WHERE user_id = (SELECT id FROM users WHERE email = 'newplayer@example.com')
ORDER BY created_at DESC
LIMIT 1;
```

---

## Next Steps

Once signup is working:

1. ✅ Test all error cases (duplicate email, weak password, missing fields)
2. ✅ Integrate with Flutter frontend
3. ✅ Add email verification flow (optional)
4. ✅ Add password reset flow
5. ✅ Add social login (Google/Apple) (optional)

---

## Performance Notes

**Signup creates 2 database records:**
1. User (in `users` table)
2. RefreshToken (in `refresh_tokens` table)

**Plus 1 query to check for duplicates:**
- Email uniqueness check
- Handle uniqueness check

**Total:** 2 SELECTs + 2 INSERTs per signup

This is optimal — you can't reduce it further without sacrificing validation.
