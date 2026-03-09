# Question Screen + Backend Consolidation Plan

## Target UX
QuestionScreen remains the main discovery and launch hub for:
- Single-player quiz modes
- Multiplayer flows
- Category/class quizzes

## Architecture Decisions
1. **Hub-first navigation**
   - Keep `QuestionScreen` as the entry point.
   - Preserve existing layout and cards; only refine routing + data source plumbing.
2. **Backend-first data strategy**
   - Read categories, stats, and daily quiz from backend endpoints first.
   - Automatically fallback to local question assets when backend is missing/unavailable.
3. **Single source of truth for game mode routing**
   - Use the shared `GameMode` model and route mapping in one place.
   - Multiplayer routes always go through `/multiplayer/...` route space.

## Delivery Phases

### Phase 1 (implemented in this PR)
- Add `QuestionHubService` as a backend-first/fallback data provider for QuestionScreen-level data.
- Wire Riverpod providers (`questionStatsProvider`, `quizCategoriesProvider`, `datasetInfoProvider`) to use backend-first reads.
- Update `QuestionScreen` preload logic to use `QuestionHubService` and remove debug-heavy local comprehensive test preloads.

### Phase 2 (in progress)
- ✅ Introduced a `QuestionRepository` interface + implementation and wired `QuestionController` + QuestionScreen-level providers to use it.
- Continue migrating remaining consumers (single-player, categories, daily, multiplayer prefetch) to repository-only access.
- ✅ Migrated `AllCategoriesScreen` and `quiz_providers` category metadata paths to repository-backed providers.
- ✅ Migrated `AllClassesScreen` and `GridCategorySection` class/category stat reads to repository-backed providers.
- ✅ Migrated category/monthly/featured challenge question providers to repository-backed methods (`getDailyQuestions`, `getMixedQuiz`, `getQuestionsForCategory`).
- ✅ Migrated remaining `quiz_providers` class/service metadata providers to repository-backed providers (`classStatsProvider`, `questionStatsProvider`, `datasetInfoProvider`).
- ✅ Migrated category stats access to repository-backed provider (`categoryStatsProvider`).
- Route all question fetches through repository methods:
  - `getQuestionsForMode(...)`
  - `getQuestionsForCategory(...)`
  - `getDailyQuestions(...)`
  - `getMultiplayerQuestions(...)`
- Add strict response contracts for backend payloads (`items`, pagination, metadata).

### UX Refinement (in progress)
- ✅ Added explicit primary launch panel on `QuestionScreen` for Single Player, Multiplayer, and Categories entry points while preserving existing design sections.

### Phase 3
- Move question creation/admin ingestion to backend workflows:
  - upload/bulk import endpoints
  - validation + dedupe server-side
  - publish/unpublish datasets
- Replace local asset-only assumptions in deeper feature areas.

### Phase 4
- Add observability:
  - request success/fallback ratio
  - endpoint latency
  - category coverage drift vs local fallback
- Remove local dataset fallback from production builds once backend parity is proven.

## Backend Contract Recommendations
- `GET /quiz/categories`
- `GET /quiz/stats`
- `GET /quiz/datasets/info`
- `GET /quiz/daily?count=5`
- `POST /quiz/play` or `GET /quiz/play` with category/mode query params

All endpoints should return stable envelopes:
- `{ items: [...], meta: {...} }` for collections
- `{ ...fields }` for singleton summaries

## Risks / Notes
- Until all screens consume the same repository, some routes will still rely on local loaders.
- Keep fallback behavior during migration to avoid blank screens when backend has partial coverage.
