# Test-suite triage

Tracks the work to make `flutter test` reliably terminate and pass in CI
(`.github/workflows/test-coverage.yml`, `flutter test --coverage`, 30-min job
timeout).

## 1. The hang (fixed — root of the CI timeouts)

**Symptom:** the full suite never finished; a `flutter_tester` isolate sat at
0% CPU indefinitely, so the CI job hit its 30-minute cap and failed. `flutter
test --timeout=Ns` could **not** preempt it (the block is native, not an async
gap the Dart timer can interrupt).

**Located to a single file** by bisecting per top-level dir, then per file:
`test/arcade/screens/arcade_screens_widget_test.dart`. It wedges on the very
first `tester.pumpWidget(DailyBonusScreen)` — `setUp` (`AppCacheService.initialize`
→ `Hive.openBox`) completes fine (the service-only arcade tests share it and
pass), and the screen itself has no timers/animations/futures, so the block is
in the headless widget pump path and is uninterruptible.

**Action:** the two widget groups are **quarantined** with `skip:` and a clear
reason, so the file terminates instantly and the suite completes. This is a
containment fix, not a root-cause fix.

**Follow-up (root cause, not yet done):** reproduce the pump hang for
`DailyBonusScreen` / `ArcadeMissionsScreen` in isolation and determine whether
it's a Hive/box interaction under the test binding or a layout path that blocks
natively; then restore the tests. Until then the two screens have no widget
coverage (their underlying services — `ArcadeDailyBonusService`,
`ArcadeMissionService` — are still covered by passing unit tests).

## 2. Verifying the suite terminates

Per-dir wall-clock (bisect, `flutter test <dir>`), post-quarantine:

| dir | result | ~time |
|-----|--------|-------|
| admin | pass | 68s |
| arcade | 261 pass / 9 skip / 15 fail | 18s |
| core | fail | 102s |
| features | fail | 34s |
| game | fail | 107s |
| integration | pass (2 skip) | 7s |
| screens | fail | 38s |
| synaptix | pass | 7s |
| ui_components | fail | 26s |
| widgets | fail | 9s |

Total ≈ 7 min — comfortably under the 30-min CI cap now that nothing hangs.

## 3. Failure categorization (full-suite JSON run)

Post-quarantine the suite completes: **7,458 tests run, 330 failures**. Grouped
by root cause (most leverage first):

| Bucket | ~count | Root cause | Status |
|--------|-------:|-----------|--------|
| **Hive not initialized** | ~130 err / ~56 tests | services call `Hive.openBox` in tests that never init Hive | **fixed** via `test/support/hive_test_env.dart` in the 5 worst files |
| Widget-test failures ("see exception logs") | ~101 | mixed; many are Hive/`getApplicationDocumentsDirectory` MissingPlugin in pumped screens | pending |
| `Null is not a subtype of ApiService` | 25 | `leaderboard_controller_test` + others missing an `ApiService` mock/override | pending |
| `Box has already been closed` | 57 (1 file) | `arcade_daily_bonus_service_test` closes the box then reuses it | pending |
| Mockito `when` within stub | 11 | nested-`when` test bug | pending |
| `_Map<dynamic,dynamic>` cast | ~5 | JSON decoded as `Map<dynamic,dynamic>`, cast to `Map<String,dynamic>` | pending |
| `SecureChannelException: decrypt` | 3 | `secure_payload_codec_test` key/nonce mismatch | pending |
| Assorted `Expected: <N>` / bool | ~60 | genuine per-test assertion/logic drift (reward math, colors, routes) | per-test |

### Shared-fix opportunities (high leverage)
- **Hive** — done for 5 files; the same `HiveTestEnv` applies to any remaining
  "need to initialize Hive" file.
- **path_provider MissingPlugin** — a `setUpAll` that stubs the
  `plugins.flutter.io/path_provider` channel (or `PathProviderPlatform` mock)
  would clear the widget-screen and `question_asset_index_loader` failures.
- **ApiService null** — most of the 25 are one shared fixture missing an
  `apiServiceProvider` override; fix the fixture, not each test.

### Duplicate test files (cleanup)
`test/core/dto/profile_service_test.dart` vs `test/game/services/profile_service_test.dart`
and `test/core/dto/skill_tree_controller_test.dart` vs
`test/game/controllers/skill_tree_controller_test.dart` are near-duplicates that
have since diverged — consolidate to one location.

## 4. Progress + refined remaining buckets

Full-suite failures: **330 → 245** (suite reliably completes; more tests now
*run* because previously-aborting files no longer die mid-file: 7,458 → 7,817).

Fixed this pass (shared helpers + targeted):
- `test/support/hive_test_env.dart` — 5 files (`question_result_service`,
  `profile_service` ×2, `skill_tree_controller` ×2) + `arcade_daily_bonus`
  (13→0, via `setUpAll`+`clear` for its fire-and-forget persists).
- `test/support/path_provider_test_env.dart` — `question_asset_index_loader`
  (3→0); cleared the plugin errors in `skill_tree_providers`.
- `leaderboard_controller` — injected real ApiService/AppCacheService for the
  fake (25→18).

Remaining 245, by nature:

| Nature | ~count | Files / approach |
|--------|-------:|------------------|
| **Genuine assertion drift** (needs a decision: stale test vs real bug) | ~120 | `profile_stats_service` (19, all `Expected:` value mismatches), `question_model` (11), `coin_balance_notifier` (7), plus the `Expected: <N>/true/false/null` spread. **Do not blind-fix** — each is either a stale expectation or a masked product bug. |
| **Widget-test failures** ("see exception logs") | 101 | attributed to `widget_tester.dart`; need per-file mapping — most should fall to the Hive / path_provider / rootBundle helpers already added. |
| **Mockito misuse** | 11 | `spin_wheel/services/cache_performance_test` uses hand-written `extends Mock implements X` (broken under null-safety); rewrite as manual fakes or add `@GenerateNiceMocks` codegen. |
| **Controller lifecycle** | 14 | `leaderboard_controller` — constructor's fire-and-forget `_loadLeaderboardState()` touches a disposed provider + trips a null String in the import path. Await the load or gate it behind a flag in tests. |
| `_Map<dynamic,dynamic>` cast | 5 | decode with `Map<String,dynamic>.from(...)` at the boundary. |
| `SecureChannelException: decrypt` | 3 | `secure_payload_codec_test` key/nonce fixture mismatch. |
| rootBundle asset load | 3 | `skill_tree_providers` — mock `rootBundle`/asset or override the graph provider. |
| Guest-gate `HttpException 401` | 2 | tests hit the now-guarded backend path; override the guest gate. |

**Recommendation:** the mechanical/shared-cause failures are largely cleared.
The largest remaining bucket is genuine assertion drift, which needs a
per-case call on whether the expectation or the code is correct — that's a
review decision, not a mechanical fix, and worth doing before any are silently
"greened".

## 4b. Grind progress — 330 → 165 (50% cleared)

The suite reliably completes; failures are down from 330 to **165**. Fixes this
pass, all committed:

| File(s) | Fix | Δ |
|---------|-----|--:|
| 5 Hive files + `arcade_daily_bonus` | `HiveTestEnv` (+ `setUpAll`/`clear` for fire-and-forget persisters) | ~69 |
| `question_asset_index_loader`, `skill_tree_providers` | `PathProviderTestEnv` stub | ~4 |
| `cache_performance` | rewrote hand-Mockito as manual fakes | 12 |
| `phase2_dashboard_integration` | `HiveTestEnv(boxes:['auth_tokens'])` | 9 |
| `performance_summary_card` | wrap in `SingleChildScrollView`; relax dup-% finders | 10 |
| `profile_stats_service` | singleton `resetForTest()` + missing `await`s | 19 |
| `question_model` | assertions → `QuestionType`/`Difficulty` enums | 11 |
| `leaderboard_widgets` | `pumpAndSettle` drains the 300ms XP-anim timer | 19 |
| `leaderboard_controller` | inject real ApiService/AppCacheService for the fake | 7 |

Reusable helpers added: `test/support/hive_test_env.dart`,
`test/support/path_provider_test_env.dart`, and a `@visibleForTesting
ProfileStatsService.resetForTest()`.

### Remaining 165, by file (top) and approach
- `leaderboard_controller` (13) — constructor's fire-and-forget
  `_loadLeaderboardState()` touches a disposed provider + a null String in the
  import path; await the load or gate it in tests.
- `answer_option_card` (9) — finder mismatches (`No element`, wrong candidate
  count); update finders to the current widget structure.
- `synaptix_home_screen` (8) — **genuine 40px RenderFlex overflow** in the
  merged SynaptixHomeScreen; a real product-layout fix, deliberately not masked.
- `coin_balance_notifier` (7), `multi_profile_providers` (4),
  `skill_tree_controller` (4), `question_result_service` (4) — provider/state
  and residual assertion drift.
- `performance_chart_provider` (6), `skill_branch_detail_screen` (6),
  `skill_tree_visualization` (6), `tier_progress_widget` (5),
  `arcade_reward_machine_widget` (4) — widget setup (Hive/path_provider helpers)
  + finder/overflow updates.
- `secure_payload_codec` (4) — crypto key/nonce fixture mismatch.
- `store_return_url_builder` (4), `event_queue_service` (4),
  `retention_entry` (3), `swatch_service` (3), `premium_store` (3),
  `tier_up_notification_dialog` (3) — mostly assertion drift → update to code.

## 4c. Grind progress — continued (≈165 → ≈139)

Further fixes, all committed:

| File | Fix | Δ |
|------|-----|--:|
| `answer_option_card` | rewrote finders for GestureDetector/AnimatedContainer (no more ElevatedButton) | 9 |
| `store_return_url_builder` | `EnvConfig.appRedirectBaseUrlForTest` set in setUp | 4 |
| `coin_balance_notifier` | expose `initialized` future (await before mutate) + `HiveTestEnv` | 7 |
| `retention_entry` | **real bug**: `weekday % 7` → `weekday - 1` (day labels were shifted) | 3 |
| `swatch_service` | **real bug**: `AppSettings.remove` deleted from the wrong box | 3 |

**Genuine product bugs found & fixed while grinding** (not masked): the
RetentionEntry weekday off-by-one, the `AppSettings.remove` box mismatch, the
`CoinBalanceNotifier` init race, and (earlier) the `profile_stats` missing
`await` + singleton leak. These are the payoff of "identify failures now."

## 4d. Grind progress — leaderboard rework + SynaptixHomeScreen layout

| File(s) | Fix | Δ |
|---------|-----|--:|
| `leaderboard_controller_test` | reworked to build a fresh `ChangeNotifierProvider` per test (no shared global → no disposed-controller leakage); draining tearDown; settles after async `_applyFilters` | 25/25 green |
| `leaderboard_entry` | **real bug**: `fromJson` read snake_case `last_active`/`user_id` while `toJson` emits camelCase → `DateTime.parse(null)` crash + `user_Id` typo; hardened round-trip | — |
| `synaptix_home_screen` | **real overflow**: wide footer's fixed 240/340 side cards (620px) inside the ~580px main column → 40px RenderFlex overflow; reworked to flexible columns | 8/8 green |
| `synaptix_home_screen` (dup #1) | **duplicate footer**: `_MainDashboard` + `_StackedDashboard` both appended a footer; footer now a single fixed scaffold slot (wide) / inline once (stacked) | — |
| `synaptix_home_screen` (dup #2) | **duplicate FriendsOnlineCard**: footer repeated the right panel's Friends card in wide/narrow; footer now shows Friends only in medium (no right panel) | — |
| `recommendations_card`, `recent_activity_card` | wrapped `ListTile` in transparent `Material` (ink/bg was hidden by the panel decoration; threw under test) | — |

Running total: **330 → ≈139** (≈58% cleared). Reusable helpers now cover the
dominant setup causes; the rest of the tail is per-file finder/overflow/assertion
work as catalogued in §4.

## 4e. Grind progress — full-suite pass (153 failures → targeted clears)

A fresh full-suite run (post-merge) reported **7,294 pass / 11 skip / 153 fail**.
The compact reporter interleaves concurrently-run files, so per-file attribution
from the log is unreliable — failing *test names* are the reliable signal. Cleared
this pass (each verified green in isolation), with the genuine product bugs called
out:

| File | Fix | Real bug? |
|------|-----|-----------|
| `energy_notifier` (20) | HiveTestEnv; `mounted` guard + `initialized` future; `_saveEnergyState` snapshots state before await | **yes** — disposal-time `state` write + save-across-await |
| `challenge_lives_notifier` (22) | HiveTestEnv; `_saveRunState` snapshots state | **yes** — constructor load clobbered a run mid-save, persisting `isRunActive:false` |
| `skill_tree_controller` (4) | `copyWith` sentinel so `selectedId` can be cleared; `restored` future | **yes** — `select(null)`/loadGraph deselect were no-ops |
| `multi_profile_providers` (15) | `ProfileManagerNotifier.ready` future + `mounted` guard; HiveTestEnv; await-before-read | **yes** — disposal race |
| `wallet_service` (9) | HiveTestEnv | no (temp-dir race) |
| `event_queue_service` (6) | unique keys; trim to `maxQueueSize`; `Map.from` decode | **yes** — same-ms key collision dropped events; hard-cast threw on retry re-put |
| `question_result_service` (4) | isolate difficulty multiplier from per-difficulty time bonus; coin rounding | no (stale fixtures) |
| tier widgets (7) | `findsWidgets` where header icon == a reward icon; scope dialog transitions | no (dup-icon assertions) |
| `secure_payload_codec` (4) | direction-parameterized AAD (defaults preserve prod); far-future session expiry | no (untestable symmetric round-trip + date rot) |
| `login_manager` (2) | map top-level `subscriptionStatus`/`premium` into metadata | **yes** — top-level premium field dropped |

Also removed two mis-filed duplicate test files under `test/core/dto/`
(`skill_tree_controller`, `profile_service`) that were strict subsets of the
canonical `test/game/**` versions.

**Needs a product decision (left unchanged):**
- `navigation_redirect_service` (2) — the tests assert an `anonymousDevice`
  identity with incomplete onboarding routes to `/login` ("device tokens do not
  bypass the login choice"), but the current service deliberately routes any
  playable identity (incl. guests) to `/onboarding`. Whether anonymous-device
  should be forced through login is an auth-policy call, not a mechanical fix.
- `premium_store` (2–3) — the store screen's layered animations + async
  `playerRewardsProvider` make the reward-card content unreliable to assert
  under the current pump strategy; needs a closer look (gated store feature).

## 4f. Grind progress — 153 → ~36 (full-suite)

Continued clearing the tail; full-suite failures now **~36** (7,385 pass / 11
skip). Additional genuine product bugs fixed at the root this pass:

| Area | Bug |
|------|-----|
| `ColorUtils.blend` | fed 0.0–1.0 Color channels into `Color.fromARGB` (0–255) → blends near-black |
| `RewardProgress.currentStepIndex` | returned `i-1`, lagging one step |
| `CategoryPieChart` | `..take(5)` cascade discarded → rendered every category |
| `QuestionFeedbackPanel` | streak badge nested in the xp/coins block; rewards shown for wrong answers |
| `ReactorReelColumn` | reel `Column` overflowed its window (no clip) |
| `getQuizStats` | `Map<dynamic,dynamic>`→`Map<String,dynamic>` threw into an empty-map catch |
| `loadSkillTreeFromAsset` | never passed a bundled fallback → skill tree failed offline/first-run |
| `ChallengeService` | const-canonical list defeated cache invalidation |
| `RichPresenceService.clearGameActivity` | `?? current` swallowed the null clear |
| `MessageReactionService` | custom-emoji premium gate missed the `customEmoji` arg |
| `ProfileService` branch clear | constructor load raced the clear, re-populating it |
| `SpectateStreamingService.watchGame` | returned a new broadcast wrapper each call |
| `EventQueueService` | same-ms key collision + trim + retry re-put cast |
| notifier saves (energy/challenge) | read `state` across awaits → half-updated persisted snapshot |
| `LoginManager`/auth | top-level `subscriptionStatus`/`premium` dropped from metadata |
| `SkillTreeState.copyWith` | couldn't clear `selectedId` |

### Remaining ~36 — categorized
- **Test pollution (pass in isolation, fail in full suite):** `auth_service`
  (×2), `multiplayer_core`, `memory_flip_controller`, `tier_progression_service`,
  `leaderboard_service`, `admin_auth_providers`, `event_queue_service` (1),
  `login_manager` (1), `multi_profile_providers` (1), `mission_model`,
  `user_profile_model`, `adapted_quiz_state`, `ws_client`, `game_flow`,
  `branch_path_helper`. These need a shared-static / Hive-box reset between
  tests, not per-file fixes.
- **Gated features (intentionally not chased):** `crypto_wallet_screen` (2),
  `crypto_providers` (2, brittle fetch-count asserts), `premium_store` (3).
- **Needs product decision:** `navigation_redirect_service` (2) — anonymous
  device → `/login` (test) vs `/onboarding` (code).
- **Complex widget/async:** `skill_tree_visualization` (4),
  `performance_chart_screen` (2), reward loading-state screens (2),
  `arcade_game_shell`, `spectate_streaming` cache (fixed), `cache_performance`.

## 4g. Grind complete — full suite green (36 → 0)

The full suite now reports **7,418 pass / 11 skip / 0 fail**, `flutter analyze`
is clean, and `dart format --set-exit-if-changed lib test` passes. Landed via
PR #287 (merged to `main`). Final clears this pass, with the genuine product
fixes called out:

| File(s) | Fix | Real bug? |
|---------|-----|-----------|
| `skill_tree_visualization` (analytics, 4) | override `skillProgressionProvider` with mock data so the data state (not the error state) renders; `devicePixelRatio` on the responsive-size tests | **yes** — header text, summary stat cards, and the tier grid overflowed at mobile widths (Flexible header, Expanded stat cards, taller `childAspectRatio`) |
| `widget_test` (SynaptixApp renders, 1) | wrap the pumped `SynaptixApp` in a `ProviderScope` (it reads providers in `didChangeDependencies`) | no (test setup) |
| `rendering_cache` (1) | `isSameColorAs` — `Paint.color` normalises to a plain `Color`, which no longer `==` a `MaterialColor` after the SDK bump | no (SDK color-equality drift) |
| `backend_profile_social` removeFriend (1) | assert the authenticated `DELETE /users/me/friends/{id}` route (both client stacks use it) instead of the old spoofable `DELETE /friends` + body | no (stale contract) |
| `settings_controller` (1) | cache the `_loadSettings()` future and await it in mutators | **yes** — an in-flight initial load could clobber a value the user just set; also cached `PlayerProfileService._getBox()`'s `openBox` future to stop concurrent double-opens |
| `premium_store` claim tests (2) | settle the staggered card scale-in before tapping; override `walletProvider` to fail fast; await the coin notifier's `initialized` before the claim | no (harness) — the earlier "gated feature" caveat is now resolved |

### CI-infra follow-ups (the green suite surfaced these)
- **`coverage` / `quality-gates` format gate** — a test edit wasn't
  `dart format`-clean; reformatted.
- **`tracked_tests` job** — `scripts/run_tests_with_tracking.sh`'s summary
  parser crashed (`'list' object has no attribute 'get'`) on a top-level JSON
  array line from `flutter test --machine`, failing the job even though every
  test passed. Guarded with an `isinstance(event, dict)` check.

## 4h. Runtime crash — Skill Tree back button (GoRouter)

Separate from the test grind: a device log showed a hard crash tapping the
back button on `/skills`. `lib/screens/skills/skill_tree_visualization.dart`
called `Navigator.of(context).pop()` directly. `/skills` is entered via
`context.go()`, which **replaces** the stack, so it can be the only page in the
shell branch — popping the last page trips GoRouter's
`currentConfiguration.isNotEmpty` assertion, cascading into a
`Navigator.dispose` `!_debugLocked` crash. Fixed by using the existing
`context.safeBack()` helper (`lib/core/navigation/navigation_extensions.dart`),
which pops when possible and otherwise falls back to `/home`.

## 5. Note on the 40% coverage gate
CI also enforces ≥40% line coverage on `lib/game/` and `lib/core/`. Fixing the
above failures (which currently abort mid-file) restores the coverage those
files were meant to produce, which is the intended path to satisfying the gate.
