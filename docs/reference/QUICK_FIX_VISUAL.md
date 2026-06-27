# QUICK FIX - Visual Reference

## What You Have Now (WRONG) ❌

```
┌─────────────────────────────────────┐
│  .env file                          │
├─────────────────────────────────────┤
│  API_BASE_URL=https://localhost:5000│  ← TWO PROBLEMS!
└─────────────────────────────────────┘
          │
          │ Problem 1: "https://" (needs SSL certificates)
          │ Problem 2: "localhost" (points to emulator, not your PC)
          │
          ↓
┌─────────────────────────────────────┐
│  Android Emulator                   │
├─────────────────────────────────────┤
│  Tries to connect to:               │
│  https://localhost:5000             │
│         ↓                            │
│  localhost = itself (emulator)      │
│  NOT your computer!                 │
│                                      │
│  Result: CONNECTION REFUSED ❌      │
└─────────────────────────────────────┘
```

---

## What You Need (CORRECT) ✅

```
┌─────────────────────────────────────┐
│  .env file                          │
├─────────────────────────────────────┤
│  API_BASE_URL=http://10.0.2.2:5000  │  ← BOTH FIXED!
└─────────────────────────────────────┘
          │
          │ ✅ "http://" (no SSL needed)
          │ ✅ "10.0.2.2" (points to your PC)
          │
          ↓
┌─────────────────────────────────────┐
│  Android Emulator                   │
├─────────────────────────────────────┤
│  Connects to:                       │
│  http://10.0.2.2:5000               │
│         ↓                            │
│  10.0.2.2 = your computer           │
│         ↓                            │
│  ┌─────────────────────────┐        │
│  │  Your Backend Server    │        │
│  │  Running on port 5000   │        │
│  └─────────────────────────┘        │
│                                      │
│  Result: CONNECTION SUCCESS ✅      │
└─────────────────────────────────────┘
```

---

## The Two Changes

### Change 1: HTTPS → HTTP

| Before | After |
|--------|-------|
| `https://` | `http://` |

**Why:** Your local backend doesn't have SSL certificates

### Change 2: localhost → 10.0.2.2

| Before | After |
|--------|-------|
| `localhost` | `10.0.2.2` |

**Why:** Android emulator's special IP for host machine

---

## Complete Line Change

```diff
# In your .env file:

- API_BASE_URL=https://localhost:5000
+ API_BASE_URL=http://10.0.2.2:5000

- API_BASE_URL_DEV=https://localhost:5000
+ API_BASE_URL_DEV=http://10.0.2.2:5000
```

---

## After Making Changes

```bash
# 1. Save .env file
# 2. STOP the app completely
# 3. Restart (DON'T use hot reload)
flutter run

# 4. Try signup again
```

---

## Platform Quick Reference

```
┌──────────────────┬─────────────────────────┐
│ Platform         │ API_BASE_URL            │
├──────────────────┼─────────────────────────┤
│ Android Emulator │ http://10.0.2.2:5000    │ ← YOU ARE HERE
│ iOS Simulator    │ http://localhost:5000   │
│ Physical Device  │ http://YOUR_IP:5000     │
│ Production       │ https://yourapi.com     │
└──────────────────┴─────────────────────────┘
```

---

## Verification Checklist

After making changes:

```
□ Changed https:// to http://
□ Changed localhost to 10.0.2.2
□ Saved .env file
□ Restarted app (not hot reload)
□ Backend is running on port 5000
```

If all checked ✓ → Should work!

---

## Expected Before/After

### BEFORE Fix:
```
Error: Connection refused
address = localhost
uri = https://localhost:5000/auth/signup
```

### AFTER Fix:
```
Success: Account created!
OR
Error: Email already exists (still success - backend responded!)
OR
Error: 400 Bad Request (still success - backend responded!)
```

Any response from backend = Fix worked! ✅
