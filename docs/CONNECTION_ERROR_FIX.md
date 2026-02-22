# 🔴 CONNECTION ERROR FIX GUIDE

## The Problem

Your error message shows:
```
Login failed: ClientException with SocketException: 
Connection refused (OS Error: Connection refused, errno = 111), 
address = localhost, port = 56172, 
uri=https://localhost:5000/auth/signup
```

## TWO Issues Found in Your .env File

### Issue 1: Using HTTPS instead of HTTP ❌
**Current:** `https://localhost:5000`  
**Problem:** HTTPS requires SSL certificates. Your local backend doesn't have them.

### Issue 2: Using localhost on Android Emulator ❌
**Current:** `localhost`  
**Problem:** On Android emulators, `localhost` refers to the emulator itself, not your computer.

---

## ✅ THE SOLUTION

### Step 1: Update Your .env File

**Location:** Your project root (same folder as `pubspec.yaml`)  
**File:** `.env`

**Change this line:**
```env
API_BASE_URL=https://localhost:5000
```

**To this:**
```env
API_BASE_URL=http://10.0.2.2:5000
```

### Step 2: Also Update DEV URL

**Change this line:**
```env
API_BASE_URL_DEV=https://localhost:5000
```

**To this:**
```env
API_BASE_URL_DEV=http://10.0.2.2:5000
```

---

## 🎯 Complete Fixed .env File

Replace your entire `.env` file with this:

```env
# API Base URLs for Different Environments

# For Android Emulator (use 10.0.2.2 instead of localhost)
# Use http:// not https:// for local development
API_BASE_URL=http://10.0.2.2:5000
API_BASE_URL_DEV=http://10.0.2.2:5000

# Staging
API_BASE_URL_STAGING=https://localhost:5000

# Production
API_BASE_URL_PROD=https://yourapi.com

# Additional environment variables
ENABLE_LOGGING=true
```

---

## 🔍 Why These Changes?

### http:// vs https://

| Protocol | When to Use |
|----------|-------------|
| `http://` | ✅ Local development (no SSL needed) |
| `https://` | ❌ Local dev WITHOUT certificates = fails |
| `https://` | ✅ Production with SSL certificates |

### localhost vs 10.0.2.2

| Address | Platform | Why |
|---------|----------|-----|
| `localhost` | ❌ Android Emulator | Points to emulator, not host |
| `10.0.2.2` | ✅ Android Emulator | Special IP for host machine |
| `localhost` | ✅ iOS Simulator | Works correctly |

---

## 📱 Platform-Specific URLs

If you test on different devices, update your `.env` accordingly:

### Android Emulator (Current)
```env
API_BASE_URL=http://10.0.2.2:5000
```

### iOS Simulator
```env
API_BASE_URL=http://localhost:5000
```

### Physical Android/iOS Device
First, find your computer's IP address:

**Windows:**
```bash
ipconfig
# Look for "IPv4 Address" (e.g., 192.168.1.100)
```

**Mac/Linux:**
```bash
ifconfig | grep "inet "
# Look for inet address (e.g., 192.168.1.100)
```

Then use:
```env
API_BASE_URL=http://192.168.1.100:5000
```

**Important:** Your phone must be on the same WiFi network as your computer!

---

## 🚀 After Updating .env

### Step 1: Stop the App
Completely stop the Flutter app (not just hot reload).

### Step 2: Restart
```bash
# Full restart (not hot reload)
flutter run

# Or from IDE: Stop and restart (don't use hot reload)
```

### Step 3: Verify Loading
Check the debug console for:
```
API_BASE_URL: http://10.0.2.2:5000
```

If you see this, the .env loaded correctly!

---

## ✅ Expected Result

After fixing, you should see:
- ✅ No more "Connection refused" error
- ✅ Either successful signup OR a backend validation error (which is good - means it connected!)
- ❌ If 404: Check your backend routes
- ❌ If still connection error: Check firewall/backend

---

## 🛡️ Firewall Check

If still getting connection errors:

### Windows
1. Windows Security → Firewall & Network Protection
2. Allow an app through firewall
3. Find your backend app and allow it

### Mac
1. System Preferences → Security & Privacy
2. Firewall → Firewall Options
3. Add your backend app

---

## 🔧 Backend Verification

Make sure your backend is actually running and accessible:

### Test from your computer:
```bash
curl http://localhost:5000/auth/signup -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","deviceId":"test-device"}'
```

### Expected Response:
- ✅ Any JSON response (even error) = backend is running
- ❌ Connection refused = backend is not running
- ❌ 404 = backend running but wrong route

---

## 🎯 Quick Checklist

Before trying signup again:

- [ ] Updated .env file with `http://10.0.2.2:5000`
- [ ] Changed `https://` to `http://`
- [ ] Fully restarted the app (not hot reload)
- [ ] Backend is running on port 5000
- [ ] Checked backend logs to confirm it's listening

---

## 🚨 Common Mistakes

### ❌ WRONG:
```env
API_BASE_URL=https://localhost:5000      # Two problems!
API_BASE_URL=https://10.0.2.2:5000       # Still using https
API_BASE_URL=http://localhost:5000       # Still using localhost
```

### ✅ CORRECT:
```env
API_BASE_URL=http://10.0.2.2:5000        # Perfect for Android emulator!
```

---

## 📊 Troubleshooting Guide

| Error | Cause | Fix |
|-------|-------|-----|
| Connection refused | Wrong URL or backend not running | Check .env and start backend |
| SSL error | Using https without certificates | Change to http |
| 404 Not Found | Backend route is different | Check backend logs |
| Timeout | Firewall blocking | Allow backend through firewall |
| Network unreachable | Wrong IP (physical device) | Use computer's actual IP |

---

## 🎉 Success Indicators

After the fix, you'll know it worked when:

1. **Connection successful** - No more "Connection refused"
2. **Backend responds** - Either success or validation error (e.g., "Email required")
3. **Logs show request** - Your backend logs show incoming POST to /auth/signup

---

## 💡 Pro Tip: Environment Switching

Create multiple .env files:

```
.env                    # Currently active (Android emulator)
.env.android           # http://10.0.2.2:5000
.env.ios               # http://localhost:5000
.env.device            # http://192.168.1.100:5000
.env.production        # https://yourapi.com
```

Switch by copying:
```bash
# For Android emulator
cp .env.android .env

# For iOS simulator
cp .env.ios .env

# For physical device
cp .env.device .env
```

---

## 🔗 Related Issues

If after this fix you get:
- **400 Bad Request** → Backend validation working, check request format
- **401 Unauthorized** → Auth working, wrong credentials
- **404 Not Found** → Backend route path different
- **500 Server Error** → Backend error, check backend logs

These are all GOOD signs - they mean the connection worked!

---

## 📞 Need More Help?

If still not working after this fix:

1. **Share backend logs** - What does backend show when you try signup?
2. **Share full error** - The new error message after .env fix
3. **Backend route** - Is your signup route `/auth/signup` or something else?

The connection error should be gone after changing to `http://10.0.2.2:5000`!
