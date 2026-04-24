# 🧩 Frontend CORS Issue – Implementation Brief

**Project:** Synaptix / Trivia Tycoon  
**Scope:** Flutter Web local development  
**Status:** ✅ Fix implemented (VS Code launch config + Android Studio run configs + `run_web.sh`)

---

## 📌 Problem Summary

The Flutter Web client (running in Edge) successfully renders the login UI but fails
to connect to the backend API due to repeated CORS (Cross-Origin Resource Sharing)
errors.

**Root causes:**

| Cause | Detail |
|---|---|
| Dynamic Flutter port | `flutter run -d edge` picks a random port on each launch |
| Strict backend allowlist | `Cors:AllowedOrigins` only permits a fixed set of origins |
| Browser preflight blocked | `OPTIONS` request rejected → all subsequent API calls fail |

---

## 🔍 Root Cause Detail

### Frontend default behaviour

- API base URL: `http://localhost:5000`
- Login request: `POST /auth/login`
- Browser sends `OPTIONS` preflight before every cross-origin POST

### Backend CORS allowlist (`Cors:AllowedOrigins`)

```
http://localhost:3000
http://localhost:4200
http://localhost:8080
http://localhost:63033
```

If Flutter runs on **any other port**, the preflight returns no
`Access-Control-Allow-Origin` header → browser blocks the request before it
reaches the API handler.

---

## ✅ Fix Implemented

### Option A – VS Code Launch Config (`.vscode/launch.json`)

Added to `.vscode/launch.json` (created if it didn't exist):

```json
{
  "name": "Flutter Web (Fixed Port)",
  "request": "launch",
  "type": "dart",
  "deviceId": "edge",
  "args": ["--web-port", "63033"]
}
```

Select **Flutter Web (Fixed Port)** from the Run & Debug panel (F5) to start on the
allowed port automatically.

### Option B – Android Studio Run Configurations (`.idea/runConfigurations/`)

Three run configurations are committed under `.idea/runConfigurations/`. Android
Studio loads them automatically when you open the project.

| Config name | Device | Port |
|---|---|---|
| Flutter Web Edge (Fixed Port 63033) | Microsoft Edge | 63033 |
| Flutter Web Chrome (Fixed Port 63033) | Google Chrome | 63033 |
| Flutter Mobile Debug | Connected device / emulator | n/a |

**To use:**

1. Open the project in Android Studio
2. Click the run configuration dropdown (top toolbar, next to the run ▶ button)
3. Select **Flutter Web Edge (Fixed Port 63033)** or **Flutter Web Chrome (Fixed Port 63033)**
4. Press ▶ Run or ⇧F10

The configurations are XML files in `.idea/runConfigurations/` — they are committed
to version control so every team member gets them automatically on `git pull`.

> If Android Studio shows "Unknown configuration type", install the **Flutter** and
> **Dart** plugins via **File → Settings → Plugins**.

### Option C – Dev Script (`run_web.sh`)

```bash
./run_web.sh          # launches in Edge on port 63033
./run_web.sh chrome   # launches in Chrome on port 63033
```

### Option D – Manual command

```bash
flutter run -d edge --web-port 63033
```

---

## 🔧 Environment Setup

Create `.env` at the project root (copy from `.env.example`):

```env
API_BASE_URL=http://localhost:5000
API_WS_BASE_URL=ws://localhost:5000/ws
```

> ⚠️ Do **not** use `https://localhost:5000` — local dev backend serves plain HTTP.

---

## 🧪 Debug Checklist

Verify each item after starting the app:

- [ ] Flutter running on fixed port (`63033`)
- [ ] `.env` is present and loading correctly
- [ ] `API_BASE_URL` resolves to the correct backend address
- [ ] No HTTP/HTTPS mismatch between frontend and backend
- [ ] Network tab shows requests being sent
- [ ] Preflight (`OPTIONS /auth/login`) returns **200** with `Access-Control-Allow-Origin: http://localhost:63033`

---

## 🔁 Expected Request Flow

```
Flutter Web (localhost:63033)
        ↓
OPTIONS /auth/login  ← preflight
        ↓
Backend validates origin against allowlist
        ↓
200 + Access-Control-Allow-Origin: http://localhost:63033
        ↓
POST /auth/login
        ↓
{ token: "...", user: { ... } }
```

---

## ⚠️ Common Pitfalls

| Mistake | Result |
|---|---|
| `flutter run -d edge` (no `--web-port`) | Random port → CORS failure |
| `API_BASE_URL=https://localhost:5000` | Invalid SSL in local dev → connection refused |
| Missing `.env` | App silently falls back to defaults; incorrect API routing |

---

## 🔒 Important Note

This is **not a Flutter bug**.

The browser is behaving correctly by enforcing CORS. The underlying issue is a strict
backend allowlist blocking dynamic frontend origins. The fix pins the frontend to an
origin that is already permitted.

---

## 📌 If Issues Persist After Using the Fixed Port

The backend team should verify:

1. `Cors:AllowedOrigins` in the active environment config includes `http://localhost:63033`
2. The correct environment profile is active (Development vs Docker)
3. `app.UseCors("Frontend")` (or equivalent middleware) is registered **before** `UseRouting` / `UseAuthentication`
4. There is no `app.UseHttpsRedirection()` silently upgrading the scheme

---

*Last updated: 2026-04-24 — added Android Studio run configurations*
