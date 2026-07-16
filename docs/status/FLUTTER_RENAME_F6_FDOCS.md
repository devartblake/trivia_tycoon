# Flutter Tycoon → Synaptix rename — Wave F6 + F-docs

**Date:** 2026-07-13  
**Depends on:** [F4+F5](FLUTTER_RENAME_F4_F5.md)

---

## Wave F6 — Paths / IDE / assets / scripts

| Before | After |
|--------|--------|
| `trivia_tycoon.iml` | `synaptix.iml` |
| `android/trivia_tycoon_android.iml` | `android/synaptix_android.iml` |
| `.idea/modules.xml` module paths | point at new `.iml` names |
| `assets/images/logo/trivia_tycoon_appLogo.png` | `synaptix_appLogo_legacy.png` |
| `scripts/import_github_issues_trivia_tycoon.py` | `import_github_issues_synaptix.py` |
| `docs/trivia_tycoon_migration_frontend_github_issues.json` | `docs/synaptix_migration_frontend_github_issues.json` |
| `docs/reference/migrations/trivia_tycoon_*` | `synaptix_*` |
| `docs/reference/planning/trivia_tycoon_backend_gap_*` | `synaptix_backend_gap_*` |
| `docs/reference/releases/TRIVIA_TYCOON_UPDATE_CHECKLIST.md` | `SYNAPTIX_UPDATE_CHECKLIST.md` |
| `docs/Tycoon_Backend_to_Trivia_Tycoon_Action_Plan.pdf` | `Backend_to_Synaptix_Action_Plan.pdf` |

### Not completed automatically

| Item | Reason |
|------|--------|
| **Local folder** `StudioProjects\trivia_tycoon` → `synaptix` | Rename failed: file lock (IDE/tools). **Manual when idle:** rename folder to `synaptix`. |
| **GitHub remote** `devartblake/trivia_tycoon` | Requires GitHub repo rename. Clone docs keep remote slug; local dir can be `synaptix`. |
| **git remote set-url** | Left as-is until GH rename exists |

README clone snippet:

```bash
git clone https://github.com/devartblake/trivia_tycoon.git synaptix
cd synaptix
```

---

## Wave F-docs — Documentation / root prose

Bulk rewrite (~**104** text files) across `docs/`, root guides, scripts, assets seeds, app-links, workflows:

| Pattern | Replacement |
|---------|-------------|
| `package:trivia_tycoon/` | `package:synaptix/` |
| `Trivia Tycoon` / `TRIVIA TYCOON` / `TriviaTycoon` | `Synaptix` / `SYNAPTIX` / `Synaptix` |
| Platform IDs in docs (`…trivia_tycoon` / `…triviaTycoon`) | `…synaptix` |
| Migration filename references | `synaptix_migration*` |
| Root `README` / `_START_HERE` / `CHANGELOG` titles | Synaptix |

**Preserved as historical (not bulk-rewritten):**

- `docs/status/FLUTTER_RENAME_F1_F2_F3.md`
- `docs/status/FLUTTER_RENAME_F4_F5.md`

**Intentionally still `trivia_tycoon`:**

- GitHub remote slug `devartblake/trivia_tycoon` (until GH rename)
- This status doc’s “before” column
- Local disk path until manual folder rename

Helper used: `scripts/_fdocs_bulk_rename.py` (safe to delete after review).

---

## Full Flutter rename series

| Wave | Scope | Status |
|------|--------|--------|
| F1 | User-facing copy | Done |
| F2 | Toast identifiers | Done |
| F3 | gRPC `synaptix.mobile` | Done |
| F4 | Dart package + imports | Done |
| F5 | Platform IDs / binaries | Done |
| F6 | Paths / assets / IDE | Done (folder + GH remote manual) |
| F-docs | Docs/prose bulk | Done |

---

## Manual follow-ups

1. Close IDE handles → rename `StudioProjects\trivia_tycoon` → `StudioProjects\synaptix`
2. On GitHub: **Settings → Rename repository** to `synaptix` (or preferred name), then:
   ```bash
   git remote set-url origin https://github.com/devartblake/synaptix.git
   ```
3. `flutter pub get && flutter analyze && flutter test`
4. Re-publish app-links `assetlinks.json` / AASA if production package name change is live (F5)
5. Optional: delete `scripts/_fdocs_bulk_rename.py`
