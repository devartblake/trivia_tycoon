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
- ✅ Added mode-aware repository entry points for all quiz fetches:
  - `getQuestionsForMode(...)`
  - `getMultiplayerQuestions(...)`
  - `getQuestionsForCategory(...)`
  - `getDailyQuestions(...)`
- ✅ Migrated `GameController` session start to repository mode-loading (`GameMode.classic`) instead of direct `QuestionService` reads.

### Phase 2 completion checklist

### Phase 2 remaining snapshot
- Completed tracks: **4 / 4** (contract parsing, repository-first wiring, provider output normalization, verification gate coverage).
- Remaining track: **Phase 2 complete**.

### Phase 2 status
- ✅ Phase 2 implementation goals are complete.
- Follow-on hardening tasks (typed DTO migration and extended audits) remain tracked as post-phase improvements.

Phase 2 completion record and post-phase follow-ups:

1. **Strict backend response contract validation**
   - ✅ Introduced typed collection/object envelope parsing for quiz backend responses.
   - ✅ Validate required fields (`items`, typed `meta`) before mapping and fallback when invalid.
   - ✅ Centralized contract/parsing errors into `QuestionContractException`.
   - 📝 Post-phase follow-up: extend typed contract models/DTOs for singleton payloads (stats + dataset variants) and retire dynamic maps in repository outputs.

2. **Repository-first cleanup**
   - ✅ Removed `QuestionRepositoryImpl` dependency on `QuestionService`; category reads now flow through `QuestionHubService` backend-first/fallback path.
   - 📝 Post-phase follow-up: continue periodic audits for any direct `QuestionService` or `AdaptedQuestionLoaderService` usage.

3. **Provider contract hardening**
   - ✅ Added normalization of repository output shapes in providers (`questionCount`, `difficulty`, class/category metadata).
   - 📝 Post-phase follow-up: add broader provider/repository regression tests as flows expand.

4. **Migration verification gates**
   - ✅ Added `QuestionHubService` tests for backend-success/local-fallback category reads, plus daily/mixed/class fallback validations.
   - ✅ Added repository routing tests for `topicExplorer`, `daily`, and `arena` mode dispatch behavior.
   - ✅ Added provider-level integration tests validating normalized repository outputs and service status composition.
   - ✅ Added multiplayer prefetch verification in `MultiplayerQuizService` and tests for repository-backed prefetch reuse and HTTP fallback when repository is unavailable.

5. **Definition of done**
   - No direct loader/service reads in quiz presentation/controller paths.
   - Contract tests in place for backend envelope parsing and fallback behavior.
   - QA pass on QuestionScreen hub routes + multiplayer entry points using repository-only data.

### UX Refinement (in progress)
- ✅ Added explicit primary launch panel on `QuestionScreen` for Single Player, Multiplayer, and Categories entry points while preserving existing design sections.

### Phase 3 (in progress)
- Move question creation/admin ingestion to backend workflows:
  - ✅ Added `QuestionIngestionService` with backend endpoints for validation, bulk import, publish, and unpublish actions.
  - ✅ Updated admin `FileImportExportScreen` with backend ingestion controls (dataset name, validate/import, publish/unpublish).
  - ✅ Added validation review UI for server-side errors/warnings in admin import flow (dedupe/conflict details now surfaced when backend returns them).
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
