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
- ✅ Migrated `ClassQuizScreen` to repository-backed class/category stats (removed simulated loader counts for primary path).
- ✅ Migrated `AdaptedQuizNotifier` (`quiz_state.dart`) to repository-backed question/class loading instead of direct local loader service calls.
- ✅ Migrated category stats access to repository-backed provider (`categoryStatsProvider`).
<<<<<<< codex/fix-error-in-user-flow-implementation-p3dgez
=======
<<<<<<< codex/fix-error-in-user-flow-implementation-ze69j1
>>>>>>> main
- ✅ Added mode-aware repository entry points for all quiz fetches:
  - `getQuestionsForMode(...)`
  - `getMultiplayerQuestions(...)`
  - `getQuestionsForCategory(...)`
  - `getDailyQuestions(...)`
- ✅ Migrated `GameController` session start to repository mode-loading (`GameMode.classic`) instead of direct `QuestionService` reads.

### Phase 2 completion checklist (remaining)
To mark Phase 2 as complete, the following still needs to be shipped:

1. **Strict backend response contract validation**
<<<<<<< codex/fix-error-in-user-flow-implementation-p3dgez
   - ✅ Introduced typed collection/object envelope parsing for quiz backend responses.
   - ✅ Validate required fields (`items`, typed `meta`) before mapping and fallback when invalid.
   - ✅ Centralized contract/parsing errors into `QuestionContractException`.
   - ⏳ Extend typed contract models/DTOs for all singleton payloads (stats + dataset variants) and retire dynamic maps in repository outputs.
=======
   - Introduce typed DTOs/envelopes for categories, stats, datasets, and quiz question payloads.
   - Validate required fields (`items`, stable `meta`) before mapping and fallback when invalid.
   - Centralize mapping/parsing errors into repository-level typed failures.
>>>>>>> main

2. **Repository-first cleanup**
   - Audit remaining feature areas for direct `QuestionService` or `AdaptedQuestionLoaderService` usage.
   - Ensure all runtime question reads use `QuestionRepository` as the sole read boundary.

3. **Provider contract hardening**
<<<<<<< codex/fix-error-in-user-flow-implementation-p3dgez
   - ✅ Added normalization of repository output shapes in providers (`questionCount`, `difficulty`, class/category metadata).
   - ⏳ Add small provider/repository tests to lock fallback behavior and prevent contract regressions.
=======
   - Normalize repository output shapes used by UI providers (`questionCount`, `difficulty`, category/class metadata).
   - Add small provider/repository tests to lock fallback behavior and prevent contract regressions.
>>>>>>> main

4. **Migration verification gates**
   - Add/enable automated checks for key flows (daily, mixed, category/class, multiplayer prefetch).
   - Capture backend-unavailable scenarios in tests to verify local fallback parity.

<<<<<<< codex/fix-error-in-user-flow-implementation-p3dgez
=======
- ✅ Added initial response-contract enforcement in `QuestionHubService` for collection endpoints (required `items` keys and `meta` on quiz payload endpoints) with fallback on invalid envelopes.

>>>>>>> main
5. **Definition of done**
   - No direct loader/service reads in quiz presentation/controller paths.
   - Contract tests in place for backend envelope parsing and fallback behavior.
   - QA pass on QuestionScreen hub routes + multiplayer entry points using repository-only data.
<<<<<<< codex/fix-error-in-user-flow-implementation-p3dgez
=======
=======
- Route all question fetches through repository methods:
  - `getQuestionsForMode(...)`
  - `getQuestionsForCategory(...)`
  - `getDailyQuestions(...)`
  - `getMultiplayerQuestions(...)`
- Add strict response contracts for backend payloads (`items`, pagination, metadata).
>>>>>>> main
>>>>>>> main

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
