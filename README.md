# Trivia Tycoon

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)]()
[![Dart](https://img.shields.io/badge/Dart-Stable-blue.svg)]()
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-success)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]()
[![State Management: Riverpod](https://img.shields.io/badge/State%20Management-Riverpod-purple.svg)]()
[![Status](https://img.shields.io/badge/Status-Active_Development-orange.svg)]()

Trivia Tycoon is a cross-platform trivia ecosystem built with Flutter. The app features a **tier-based ranking system**, **dynamic XP missions**, **a honeycomb skill tree**, **an offline-first architecture**, **QR code systems**, and **full administrative tools** for managing questions, analytics, encryption, and user behaviors.

This repository includes the entire player-facing and admin-facing Flutter application.

---

## 🖼️ Screenshots & Demo

> Add your real screenshots to `assets/screenshots/` and update paths below.

### 📱 Gameplay
<img src="assets/screenshots/gameplay.png" width="300">

### 🧠 Skill Tree (Honeycomb Layout)
<img src="assets/screenshots/skill_tree.png" width="300">

### 🏆 Leaderboard (Tier System)
<img src="assets/screenshots/leaderboard.png" width="300">

### 🛠 Admin Dashboard
<img src="assets/screenshots/admin_dashboard.png" width="300">

### Mini Games
<img src="assets/screenshots/mini_games.png" width="300">

---

## 🎞️ Demo GIFs

> Add demo animations to `assets/demos/`.

- **Skill Tree Animation**  
  <img src="assets/demos/skill_tree.gif" width="350">

- **QR Scanner**  
  <img src="assets/demos/qr_scanner.gif" width="350">

- **Mission Completion Animation**  
  <img src="assets/demos/mission_xp.gif" width="350">

---

## ✨ Core Features

### 🧠 Gameplay & Player Progression
- Honeycomb-style skill tree (Knowledge, Power-ups, Strategy)
- Daily/weekly missions with XP, streaks, and bonuses
- Animated XP bar with glow and transitions
- Question categories, difficulty scaling, and media support

### 🏆 Ranking System
- Global + Tier-based ranking structure  
- 100 players per tier  
- Top 25 = promotion eligibility  
- Top 20 = daily rewards  
- Auto-scroll to player within tier

### 📊 Leaderboard & Player Profiles
- Streaks, engagement scores, activity tracking
- Country flag, rank badges, XP stats
- Profile QR sharing

### 📱 QR Ecosystem
- Custom QR generator (no external packages)
- Custom QR decoder engine
- Scan preview modal and full scan history
- Scan-type filters (profile, referral, mission, promo)

### 🛠 Admin Tools
- Question editor with tags, media, and encryption support  
- Question list with bulk delete, search, filtering  
- Encryption Manager (AES & Fernet)  
- Mission analytics dashboard  
- Scan analytics dashboard  
- Splash screen selector + animated previews  

---

## 🧰 Tech Stack

| Layer | Technology |
|------|------------|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Offline Storage | Hive |
| Encryption | AES + Fernet |
| Router | GoRouter |
| Backend Integration | FastAPI or .NET microservices |
| QR | Fully custom painter & decoder engine |

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK (matching version in `pubspec.yaml`)
- Xcode (macOS), Android SDK (any platform)
- Optional: API backend for online sync

### 2. Clone Project
```bash
git clone https://github.com/devartblake/trivia_tycoon.git
cd trivia_tycoon

---

### 3. Install Dependencies
```bash
flutter pub get

### 4. Configure the App
Depending on your setup, you may need to configure:
	•	API endpoints (e.g., dev/stage/prod).
	•	Encryption keys or secure tokens (stored via SecureStorage and not committed).
	•	Feature flags (e.g., enable/disable QR scanner, missions, admin tools).

Typical patterns:
	•	lib/config/ for environment constants.
	•	.env / --dart-define values (if used in this repo).

Update this section to match your actual configuration files and environment flow.

#### Logging noise controls
If you run a local ASP.NET backend and want quieter console output, set these environment variables:

```bash
ENABLE_LOGGING=false
Logging__LogLevel__Default=Warning
Logging__LogLevel__Microsoft.AspNetCore=Warning
```

This preserves warnings/errors while suppressing per-request informational lines such as request start/finish and endpoint execution traces.

### 5. Run the App
Run on a connected device or emulator:
```bash
flutter run
