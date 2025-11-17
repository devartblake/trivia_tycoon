# Trivia Tycoon

Trivia Tycoon is a cross-platform trivia game built with Flutter, designed around **long-term progression**, **Theory-of-Mind (ToM)-inspired targeting**, and **admin-grade controls**.  

Players climb through ranks and tiers, complete missions, unlock a honeycomb-style skill tree, and compete on a rich, analytics-driven leaderboard. Admins get tools for managing questions, scan history, encryption, analytics, and more.

---

## ✨ Key Features

### 🧠 Gameplay & Progression

- **Multi-category trivia**: Questions across categories (e.g., general knowledge, school-aligned content, themed packs).
- **Skill Trees & Honeycomb Layout**  
  - Knowledge, Strategy, and Power-up branches.  
  - Unlocks that meaningfully affect gameplay (time boosts, hint behavior, lifelines, category bonuses).
- **Tier-based Rank System**
  - Global tiers with ~100 players per tier.  
  - Tier rank vs global rank, with promotion/reward thresholds.
- **Missions & XP**
  - Daily / weekly missions (streaks, category goals, difficulty challenges).  
  - XP and rewards that tie into rank, unlocks, and cosmetics.

### 🏆 Leaderboard & Analytics

- **Tier-aware leaderboard** with auto-scroll to the current player.
- **Enhanced player profiles** with:
  - XP bar & level
  - Rank & tier info
  - Engagement score
  - Subscription/account status
- **Admin filters** for:
  - Bots vs human players  
  - Device type, notification preferences, premium users  
  - Power-up holders and high-engagement players

### 📱 QR & Sharing System

- Built-in **QR generator** and **scanner**:
  - Custom QR painter and scanner widgets.
  - Scan history with timestamps and filtering by scan type.
  - Optional deep behaviors (launch URL, copy ID, share profile, etc.).

### 🛠️ Admin & Tools

- **Admin Dashboard** with:
  - Question editor and question list (tags, bulk actions, filters).
  - Encryption manager (Fernet/AES) for secure data.
  - Mission analytics & scan analytics.
  - Splash screen selector and animated splash previews.
- **Config & Settings**
  - Modular settings services (audio, theme, quiz, etc.).
  - App-wide `ServiceManager` to centralize services like API, cache, encryption, analytics.

---

## 🧰 Tech Stack

- **Frontend:** Flutter (Dart)
- **State Management:** Riverpod
- **Local Storage / Cache:** Hive (via `AppCacheService` / `SecureStorage` abstraction)
- **Config & Settings:** Modular settings services (e.g., `AudioSettingsService`, `QuizProgressService`, etc.)
- **Encryption:** AES + Fernet utilities and services
- **Backend (planned / integrated):**
  - FastAPI / .NET microservices for game data, analytics, and sync
  - PostgreSQL & other data stores (depending on environment)

> Note: This repository is focused on the Flutter client. Backend services live in separate repos.

---

## 🚀 Getting Started

### 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (matching the version used in this project)
- Dart SDK (bundled with Flutter)
- A recent version of:
  - Android Studio, IntelliJ IDEA, or VS Code with Flutter extension
- Optionally:
  - Running instance of the Trivia Tycoon backend (FastAPI / .NET) if you are testing online features.

### 2. Clone the Repository

```bash
git clone https://github.com/devartblake/trivia_tycoon.git
cd trivia_tycoon