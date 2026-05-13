# Current Tasks

_Generated from the markdown files in `docs/` on 2026-05-10._
_PR/branch cross-check pass: 2026-05-10 against `origin/main`, recent remote branches, and known merged PR metadata. No specific active PR number was supplied, so branch heads were also used as the working source of truth._

> This file reconciles the current remaining work from the docs folder. Older completed or superseded checklist items are omitted where newer status docs mark them done.

## P0 - Alpha / Release Blockers

### Runtime validation on device + live backend
- [ ] Validate app launch, auth/bootstrap, login, signup, logout, token refresh, and session resume on a real device/emulator with a live backend.
- [ ] Validate onboarding restore, first challenge completion, reward reveal, and completion handoff to `/home`.
- [ ] Run kids, teen, and adult mode QA for layout, copy, navigation, and mode-specific rendering.
- [ ] Verify all core Synaptix surfaces are reachable: Hub, Arena, Labs, Pathways, Journey, Circles, Command, Store, Rewards.
- [ ] Confirm no high-visibility stale "Trivia Tycoon" labels remain in runtime UI.

### Auth / local web verification
- [x] Add gated live Dart smoke coverage for local Docker/staging auth, CORS preflight, login, `/users/me`, `/users/me/wallet`, refresh, and Spin & Earn confirmed endpoints.
- [x] Confirm `AuthHttpClient` is registered correctly in the Riverpod/provider graph: `authHttpClientProvider` feeds `httpClientProvider`, and `ServiceManager` builds the same backend auth chain.
- [x] Verify login errors for 401, 403, 422, and network timeout with focused `AuthErrorMessages` coverage.
- [x] Verify signup validation and backend error-code display with focused `AuthErrorMessages` coverage.
- [x] Test 401 auto-refresh end-to-end against stub backend coverage in `api_service_test.dart` and gated live refresh coverage in `live_backend_smoke_test.dart`.
- [x] Verify backend profile hydration path after login/signup through `AuthOperations._hydrateProfileFromBackend`; emulator/data-wipe runtime verification remains covered by the live smoke/manual checklist.
- [x] Resolve local web CORS verification: backend Docker CORS config now includes `http://localhost:63033` and `http://127.0.0.1:63033`; `OPTIONS /auth/login` returned `204` with `Access-Control-Allow-Origin` on 2026-05-10.

### Friends, social, and presence verification
- [ ] Live-verify `GET /users/me/friends`, request lists, sent requests, suggestions, authenticated `/users/search`, and authenticated `DELETE /friends`.
- [ ] Two-account/device QA: send request, accept, decline, cancel, block/unblock, unfriend, nickname/favorite state, and DM recipient picking.
- [ ] Presence QA: initial `presence.bulk`, `presence.update` during quiz/match activity, reconnect behavior, and offline transitions on disconnect.
- [x] Remove/deprecate `FriendDiscoveryService`; no `friend_discovery` source file remains in `lib/`.

### Economy, wallet, store settlement
- [x] Map authoritative backend wallet fields from `GET /users/me/wallet`: `credits -> coins`, `neuralXp -> xp`, `synapseShards -> diamonds`.
- [x] Bridge backend wallet refresh into legacy coin, diamond, and XP providers while keeping Hive/local wallet state as cache/fallback.
- [x] Refresh authoritative wallet state after Spin & Earn claim, reward claim, avatar purchase, and payment-return purchase reconciliation.
- [x] Integrate remaining shared wallet counters with authoritative backend state from `GET /users/me/wallet` by syncing legacy `playerCoinsProvider`, `playerGemsProvider`, and Hive wallet cache.
- [x] Add test coverage for displayed wallet field mapping: credits, neural XP, and Synapse Shards after backend wallet fetch.
- [x] Route coin/diamond store purchases through backend `purchaseWithCoinsOrDiamonds` when a SKU exists, then refresh wallet, catalog, and inventory providers; local fallback remains for offline/dev-only catalog items.
- [x] Validate store service settlement contracts for IAP validation, reward claims, PayPal/Stripe return routing, and payment return reconciliation with focused service/screen tests.
- [ ] Run staging settlement smoke: store purchase settlement, inventory refresh, subscription entitlement refresh, IAP validation, Stripe/PayPal return reconciliation, and reward reconciliation after daily/weekly/spin/mission claims. This requires staging credentials/payment test setup and cannot be completed from local code alone.

### Pending database / DevOps actions
- [ ] Apply pending backend EF migrations to staging/prod or confirm already applied: season reward rules, store stock system, flash sales, reward claim rule, effective max quantity.
- [ ] Verify store stock/admin store endpoints behave correctly after migrations.
- [ ] Deploy hosted app-link verification files: `assetlinks.json` and `apple-app-site-association`.
- [ ] Clean native rebuild/reinstall after adding `app_links` to avoid stale `MissingPluginException`.

## P1 - High-Value Implementation

### Crypto economy surfaces
- [x] Add typed crypto service, models, and providers for wallet link, balance, history, withdraw, stake, unstake, staking status, and prize pool actions.
- [x] Base crypto wallet screen exists for balance/history, wallet linking, withdrawals, staking, unstaking, and prize pool interaction.
- [x] Add service/provider tests for crypto endpoint contracts, mutation invalidation, and backend error envelope mapping.
- [x] Add feature flags for staged crypto rollout and safe disabling: `CRYPTO_SURFACES_ENABLED`, `CRYPTO_WRITES_ENABLED`, and `CRYPTO_ENABLED_NETWORKS`.
- [x] Live-validate crypto contracts against local Docker: disposable signup plus balance, history, staking, prize-pool reads, and secure-channel write guard verified against `http://localhost:5000` on 2026-05-10.
- [ ] Run the same crypto contract smoke against staging once staging base URL and credentials are supplied.
- [x] Add/extend crypto UI smoke tests for linked/unlinked, pending withdrawal, disabled-feature, stake/unstake, and prize pool states. (`test/screens/store/crypto_wallet_screen_test.dart` — 8 widget tests covering disabled feature, unlinked, linked, balance, staked units, staking summary, pending withdrawal, empty history)

### Rewards backend integration
- [x] Wire confirmed Spin & Earn endpoints: `GET /arcade/spin/segments` and `POST /arcade/spin/claim`.
- [x] Keep local segment/stat/history fallback when backend Spin & Earn calls fail.
- [x] Add gated smoke coverage for authenticated segment fetch and authorized spin claim route behavior.
- [x] Replace local-only daily reward config and claim state with server endpoints once backend confirms them.
- [x] Replace weekly login streak Hive state with server streak/schedule/claim APIs once backend confirms them.
- [x] Persist spin stats/history server-side when the server stats/history endpoints are available.
- [x] Replace local spin stats/history with server stats/history where available; keep local cache only as offline fallback.
- [x] Fix `hybrid_mission_state.dart` `currentUserIdProvider` stub by using the real profile/auth user provider.
- [x] Wire confirmed mission list and claim flows to backend endpoints: `GET /missions` and `POST /missions/{missionId}/claim`.
- [x] Wire mission progress event submission to `POST /missions/progress/match-completed` and `POST /missions/progress/round-completed` from real gameplay completion events.
- [x] Keep mission swap/generate/delete local-only until backend confirms replacement endpoints.
- [x] Move hardcoded reward step presets behind a provider once a configurable backend endpoint exists.

### Portable avatar persistence
- [x] Avatar upload service accepts `XFile`, sends filename/content length, performs presigned MinIO PUT, and returns the persisted avatar URL.
- [x] `ProfileAvatarController` is wired with upload/profile-sync services and exposes upload progress, error, retry, and remote URL state.
- [x] Profile UI shows avatar upload progress/error/retry state.
- [x] Upload service and controller tests cover success, failure, retry, and persisted URL state.
- [ ] Runtime-verify emulator wipe/login rehydrates avatar from backend URL instead of a local device path.

### Secure channel rollout
- [x] Add `deleteEncrypted` to `EncryptedApiClient` and route DELETE-sensitive social operations through encrypted semantics: `removeFriend`, `cancelFriendRequest`, and `unblockUser`.
- [x] Encrypt selected private social/economy endpoints through the current rollout: friend request send/accept/decline/cancel/remove, block/unblock, loadout save, and Spin & Earn claim.
- [x] Add secure-channel tests for wrong nonce, logout/session clear, and 1 KB/10 KB/100 KB payload coverage.
- [x] Add remaining secure-channel tests for wrong sequence/replay, expiry renewal, reinstall invalidation, and web fallback. (`test/core/security/secure_payload_codec_test.dart` — 15 new tests in 3 groups: replay/sequence, SecureSession model, SecureSessionStore reinstall/web-fallback)
- [ ] Decide and schedule any later refresh/match/economy/messages/private social write expansion beyond the currently selected endpoints.
- [ ] Validate exact backend response schema, replay protection, and sequence semantics against staging.

### Admin security and operations UI
- [ ] Build dead-letter/security event list and replay UI.
- [ ] Build `/admin/audit/security` timeline page.
- [ ] Decide whether central admin notifications should be server-managed or remain local-only.
- [ ] If server-managed, wire `/admin/notifications*` endpoints.
- [ ] Confirm admin auth choices: MFA, token lifetime, refresh rotation, permission scopes, enum values, bulk question mode, event dedupe key, config locality.

### Skill tree / Pathways cleanup
- [x] Normalize branch navigation so cards, route icons, Auto-Path, and search use `/skill-branch/:branchId`.
- [x] Remove duplicate branch overlay rendering from `SkillBranchDetailScreen`; branch detail now uses `AutoPathOverlayPainter`.
- [x] Clarify/rename branch coordinate provider via `branchWorldCentersProvider`; `branchCentersProvider` remains as a compatibility alias.
- [x] Move path recomputation out of build-time mutation in `SkillBranchDetailScreen`.
- [x] Make `MiniHexBranchPreview.fromGraph` use the provided graph through `graphOverride`.
- [x] Replace free-form radial BFS layout with true axial hex-grid positioning: `master_hub` at `(0,0)`, 12 branch roots at ring-2, tier nodes extending along branch direction vectors. `HexMetrics.axialToPixel` converts to world pixels. (`lib/game/controllers/skill_tree_controller.dart`, branch `claude/fix-hexagon-alignment-CrQVu`)
- [ ] Decide whether debug overlay controls ship, hide behind a flag, or move to debug builds only.

## P2 - Quality, Tests, and Release Hardening

### Test coverage
- [x] Add `RichPresenceService` tests for initialization, update, game activity, joinability, watched streams, and dispose.
- [x] Add auth edge-case tests: social login (`getOAuthUrl`), concurrent 401 refresh, offline login (SocketException), logout token cleanup (401 best-effort), expiry detection, metadata extraction. (`test/core/services/auth_service_test.dart`)
- [x] Expand widget tests for `DailyBonusScreen` and `ArcadeMissionsScreen`: renders correctly, coin/gem values, streak states, wallet counters, mission catalog. (`test/arcade/screens/arcade_screens_widget_test.dart`)
- [x] Expand skill tree widget tests: `showPath=0` disables highlight, step 0 label, out-of-bounds step clamps without crash. (`test/screens/skills_tree/skill_branch_detail_screen_test.dart`)
- [x] Expand widget tests for `ArcadeGameShell` — mounts correct game widget per `ArcadeGameId`. (`test/arcade/screens/arcade_game_shell_test.dart` — 5 tests: patternSprint, memoryFlip, quickMathRush mount, ArcadeRunApi accessible via `.of()`, difficulty passed to builder)
- [x] Expand leaderboard interaction tests (`AnimatedRankBadge`, `EnhancedScoreDisplay`). (`test/widgets/leaderboard_widgets_test.dart` — added 6 `AnimatedRankBadge` interaction tests: up/down arrow icons, no-arrow states, animation completion; added 14 `EnhancedScoreDisplay` interaction tests: performance messages for all 5 tiers, percentage label, XP section visibility, XP animation final value, category breakdown, power-up section, class level badge)
- [x] `LoginManager` unit tests: role extraction (`role`/`roles`/`tier` fields), premium status (`isPremium`/`subscriptionStatus`/`tier`), `getNextRoute()` routing, `isLoggedIn()` state, userId persistence. (`test/core/manager/login_manager_test.dart` — 16 tests across 5 groups)
- [x] `AuthTokenStore` + `AuthSession` unit tests: hasTokens, isExpired, role/roles/isPremium/tier getters, copyWith, toJson/fromJson, load/save/clear/updateAccessToken/getRole/isPremium on store — 30+ tests. (`test/core/services/auth_token_store_test.dart`) ✅ NEW
- [x] `AuthStateNotifier` + `AuthState` provider tests: initial state, login, signup, logout, setRole, setPremiumStatus, clearError, `isLoggedInSyncProvider`, `profileSelectedProvider` — 20+ tests. (`test/game/providers/auth_providers_test.dart`) ✅ NEW
- [x] `LeaderboardController` tests: initial state, setCategory, applySorting, category filter (daily/weekly/global), sorting by score/rank, promoteUser, banUser, pause/resume, exportLeaderboardData, isFilterActive, getLeaderboardStats — 25+ tests. (`test/game/controllers/leaderboard_controller_test.dart`) ✅ NEW
- [x] `QuestionController` + `QuestionState` tests: initial(), copyWith, computed properties (accuracy, isQuizOver, currentQuestion), initial provider state, isSelected, selectAnswer (normal/guard/post-reset), reset, usePowerUp — 20+ tests. (`test/game/controllers/question_controller_test.dart`) ✅ NEW
- [x] `UserWallet.fromJson` field mapping tests: credits→coins, neuralXp→xp, synapseShards→diamonds, defaults, doubles, `UserWallet.empty` — 15+ tests. (`test/core/models/user_wallet_model_test.dart` expanded) ✅ NEW
- [x] `CoinBalanceNotifier` tests: initial state, add (accumulate/zero), deduct (sufficient/insufficient/exact), canAfford, set, reset, persistence round-trip — 20+ tests. (`test/game/controllers/coin_balance_notifier_test.dart`) ✅ NEW
- [x] `EnergyState.copyWith` + `EnergyNotifier` tests: initial state, canPlay*/useEnergy/addEnergy/syncWithServer methods, constant validation — 25+ tests. (`test/game/controllers/energy_notifier_test.dart`) ✅ NEW
- [x] `WalletService` tests: addCoins/addGems (positive/zero/negative), spendCoins/spendGems (sufficient/insufficient/exact/zero), setBalances (clamps negatives), coins/gems independence — 20+ tests. (`test/game/services/wallet_service_test.dart`) ✅ NEW
- [x] `currentUserIdProvider` fallback chain tests: stored userId → email prefix → player name → guest; `PlayerProfileService` and `LocalAuthService` integration — 12+ tests. (`test/game/providers/profile_providers_test.dart`) ✅ NEW
- [x] `StatePersistenceService` Hive-backed tests: initialize (fresh box, idempotent), saveAll (each key independently and combined), getGameState/getUserSession/getWebSocketState/getPendingActions (present and absent), getLastSaveTime (null pre-save, valid post-save, updates each call), clearPendingActions/clearTemporaryData/clearAll, hasRecoverableData (crash flag + data combinations), getRecoverySummary, markRecoveryHandled, uninitialized guard — 25+ tests. (`test/core/services/state_persistence_service_test.dart`) ✅ NEW
- [x] `SkillTreeGraph` + `SkillNode` + `SkillEdge` + `SkillNodeCooldown` tests: SkillCategory groupId/brandId for all values, SkillNode.fromJson (all fields, defaults, category/effectType/cooldown/effects parsing, bool-to-num conversion), SkillNode.copyWith, SkillNodeCooldown isOnCooldown/remainingCooldown/canUse, SkillEdge.fromJson, SkillTreeGraph byId/tier/maxTier/getNodeById/nodesInGroup/nodesInBranch/canUnlock/getPrerequisites/getDependents/availableNodes/unlockedNodes/withUnlockedIds/fromJson/copy, subgraphForBranch/indegree/neighbors extension — 60+ tests. (`test/game/models/skill_tree_graph_test.dart`) ✅ NEW
- [x] `LeaderboardEntry.fromJson/toJson/copyWith` tests: all scalar fields (userId int and string, playerName, score, rank, tier, tierRank, booleans, wins, level, country/state/countryCode, xpProgress/accuracy/sessionLength, emailVerified, isBot, subscriptionStatus, averageAnswerTime, engagementScore), DateTime fields (lastActive/timestamp/joinedDate), list fields (interests/powerUps, empty defaults), default fallbacks (Unknown/0/1/active/UTC/free), toJson serialization, copyWith field coverage, fromJson round-trip — 35+ tests. (`test/game/models/leaderboard_entry_test.dart`) ✅ NEW
- [x] `AdaptedQuizState` tests: default constructor values, copyWith for all numeric/bool/string/collection/DateTime/Duration fields, preserves unchanged fields, currentQuestion (null/first/nth/out-of-bounds), totalQuestions, isLastQuestion, scorePercentage (zero/full/partial/empty), quizDuration (null start/start+end/start only), categoryDisplayName — 40+ tests. (`test/game/state/adapted_quiz_state_test.dart`) ✅ NEW
- [x] `AvatarEntry/AvatarPackage/AvatarPackageRenderHints/AvatarPackageMetadata/AvatarPackageInstall/FolderIndex/AvatarPackageManifest` tests: fromJson/toJson/copyWith for all classes, enum parsing (AvatarSource/AvatarKind/AvatarPackageType), override parameters (sourceOverride/kindOverride/packageIdOverride), defaults, installFolderName computed property, FolderIndex.decode from JSON string — 55+ tests. (`test/game/models/avatar_package_models_test.dart`) ✅ NEW
- [x] `QuestionModel` + `Answer` tests: Answer fromJson/toJson, QuestionModel.fromJson (answers-list path: correctIndex from isCorrect/optionId/correctOptionId/expectedAnswer, optionIdByText from answers/id fallback; options-list path: strings and maps; optional fields: imageUrl/mediaKey/audioUrl/tags/reducedOptions/isBoostedTime/isShielded; defaults), _parseDifficulty (numeric/easy/medium/hard/expert/string-number/null/case-insensitive), hasAudio/hasVideo/hasImage/mediaType/isMultimedia, checkAnswer, isCorrectAnswer, optionIdForAnswer, answerTextForOptionId, toJson, copyWith, fromGameplayDto — 55+ tests. (`test/game/models/question_model_test.dart`) ✅ NEW
- [x] `Mission` + `UserMission` tests: _parseMissionType (daily/weekly/seasonal/one_time variants), _parseMissionStatus (completed/complete/expired/swapped/unknown→active), Mission.fromJson (id/missionId fallback, title underscore replacement/key fallback/'Mission' default, progress/total/goal/rewardXp fallbacks, icon mapping for all 8 icons + default, DateTime fields, description/expiresAt optionals), isCompleted/isExpired/progressPercentage, toJson (type.name/status.name), copyWith; UserMission.fromJson (nested mission, claimed/completed flags→completed status, swap_count, assignedAt), isCompleted/canSwap/progressPercentage, copyWith, toJson — 55+ tests. (`test/game/models/mission_model_test.dart`) ✅ NEW
- [x] `PVPChallenge` + `PVPChallengeStatus` + `PVPChallengeResult` tests: PVPChallengeStatus displayName for all 6 values, isActive/isPending/isFinished, PVPChallenge.fromJson (all scalar/DateTime/optional fields, status via byName, wager default), hasWager, isExpired (past/future/finished-status), timeRemaining, getWinnerName (null/challengerName/opponentName), toJson (status.name, ISO dates, conditional optional fields), copyWith; PVPChallengeResult isDraw/scoreDifference (positive difference, negative difference normalized, zero) — 50+ tests. (`test/game/models/pvp_challenge_models_test.dart`) ✅ NEW
- [ ] Move toward the documented 40% coverage target for `lib/game/` and `lib/core/` (remaining: AuthOperations integration, notification service, quiz_category.dart, skill_effect_handler.dart).

### Dependency and build health
- [ ] Run `flutter pub outdated` and apply safe security/minor updates.
- [ ] Run `flutter pub deps --style=compact` and remove unused dependencies from retired features.
- [ ] Install `nuget.exe` on Windows PATH; verify `nuget help`, `flutter clean`, `flutter pub get`, and `flutter build windows`.
- [ ] Configure CI to enforce analyze/tests/coverage and prevent raw production `debugPrint` regressions.

### Product polish
- [ ] Expand sound cues beyond Hub to Arena, Labs, Pathways, Journey, Circles, and Command.
- [ ] Standardize SFX taxonomy, shared cue helper, volume profiles, settings gating, fallback behavior, and cue tests.
- [ ] Run low-end Android and iOS audio latency/fatigue QA.
- [ ] Complete final empty-state copy sweep and mode-specific accessibility pass.
- [ ] Verify frontend labels, preferences payloads, and analytics payloads against backend dashboards/docs.

### Questions, Play, Learn, Study cleanup
- [x] Align gameplay question parsing to backend `GameplayQuestionDto`: `text`, `options`, `mediaKey`, no embedded correctness, and `Easy/Medium/Hard/Expert` difficulty mapping.
- [x] Route single-player, category, class, and multiplayer question loading through `QuestionHubService` and `GET /questions/set` with the correct `mode` contract.
- [x] Keep class/grade gameplay as frontend category+difficulty mapping; no nonexistent `/questions/classes/*` gameplay endpoint is required.
- [x] Make multiplayer use `mode=ranked`, count-only, and no `playerId` personalization for fair question sets.
- [x] Remove stale direct multiplayer `/api/questions` fetch fallback; repository/hub is primary and local mock fallback remains only after repository failure.
- [x] Use `/questions/check` and `/questions/check-batch` as the correctness source for backend questions, posting `selectedOptionId` and mapping `correctOptionId` back to answer text.
- [x] Extend gated live smoke coverage for `/questions/set`, `/questions/check`, and `/questions/check-batch`.
- [ ] Live-verify gameplay stays on backend question data in local/staging/prod.
- [ ] Run targeted Flutter/Dart tests for question model parsing, service query contracts, category/class launch, and multiplayer routing once SDK tooling is available.
- [ ] Decide whether local question fallback remains enabled in production after backend parity is proven.
- [ ] Add source observability beyond banners/logging: backend success ratio, latency, and coverage drift.
- [ ] Introduce `/play` route aliases, remove or redirect frontend `/quiz/*` routes where safe, and align labels from Quiz to Play.
- [ ] Create one launcher/orchestrator for route params to question session state and remove ambiguous router imports.
- [ ] Add learning progress summary, recommended module logic, continue-learning CTA, reward transparency, and idempotent lesson/module completion retries.
- [ ] Remove deprecated `ApiService` and `SynaptixApiClient` quiz methods after all callers are migrated; active gameplay callers are no longer using `ApiService.fetchQuestions()`.
- [ ] Update route maps and tests.

## P3 - Deferred / Decision-Gated

### Cross-check notes
- [ ] If there is a specific active PR number, re-run this cross-check against that PR number's changed files and patches.
- [ ] Known merged PR metadata was spot-checked, including PR #158 for Phase 3 test coverage pass 2.
- [ ] Recent remote branches indicate several task slices may also be PR-style branch work, especially `copilot/stn-*` skill-tree branches and `claude/fix-hexagon-alignment-CrQVu`.

### Packet E package root rename
- [ ] Wait for product/legal store transition plan before changing package root or bundle IDs.
- [ ] Rename `pubspec.yaml` package from `trivia_tycoon` to `synaptix`.
- [ ] Update all `package:trivia_tycoon/...` imports.
- [ ] Change Android application ID and iOS bundle identifier to `com.theoreticalmindstech.synaptix`.
- [ ] Regenerate Firebase/Google service configs and `build_runner` outputs.
- [ ] Document rollback strategy and run the rename in an isolated branch.

### Backend Packet E
- [ ] Defer backend namespace rename from `Tycoon.Backend.*` to `Synaptix.Backend.*` until after Alpha/stable release.
- [ ] Later rename service/telemetry identifiers, Docker/CI labels, Elasticsearch aliases, and related ops naming.

### Optional ML / personalization UX
- [ ] Keep personalization frontend paths on the current `/personalization/{playerId}/...` contract and clean up older docs that show superseded paths.
- [ ] Decide whether churn-risk and match-quality ML signals need visible UX in this sprint.
- [ ] If yes, add or expand typed providers/UX for ML-driven nudges behind feature flags.
- [ ] Track `source` values such as `deployed-model` vs `heuristic` only as optional telemetry/UX context.

### Backend-dependent future APIs
- [ ] Do not wire `GET /v1/assets/audio/{category}/{filename}` until backend marks it live.
- [ ] Treat premium DB-backed catalog phase 2 and richer gift/cosmetic/avatar purchase contracts as post-launch unless reprioritized.
- [ ] Add stronger store feature flags via `/store/system/status` if backend exposes the endpoint.
