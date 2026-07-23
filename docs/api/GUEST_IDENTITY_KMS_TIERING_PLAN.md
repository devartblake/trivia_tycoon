# Guest identity + KMS tiering plan

Direction approved: **tiered identities** — keep frictionless guest play, but stop
giving throwaway device-guests the same heavyweight KMS treatment as real
accounts. The KMS does heavy lifting only from "platform-linked" upward.

This spans two repos: `trivia_tycoon` (Flutter client) and
`TycoonTycoon_Backend` (.NET API + `Synaptix.Security.Kms.*`).

## Current architecture (grounded)

- **Secure channel = a KMS session.** The client establishes it via
  `POST /api/v1/security/sessions/start` (`SecureChannelService._doStartSession`,
  X25519 ECDH + HKDF), bound server-side to **subject + deviceId**
  (`SecureSessionService.StartAsync`). The KMS runs as a **separate service**
  (`KmsClient:BaseUrl`, `:5060` in dev).
- **Only 16 endpoints require the channel** (`RequireSecureChannel`), all
  sensitive: store purchases / IAP / subscriptions / restore (8), crypto wallet
  link/withdraw/stake/unstake (5), admin auth (2), and **`/auth/refresh`** (1).
  Gameplay, rewards, tiers, leaderboards, friends do **not** need it.
- **The channel is already established on demand** for gated calls:
  `EncryptedApiClient` does `loadSession()` → if null, `startSession()`
  (`lib/core/networking/encrypted_api_client.dart`).
- **But the client also pre-warms it eagerly at launch:**
  `_ensureSecureSessionForAuthRefresh` is called from every auth path
  (`lib/game/providers/auth_providers.dart`), including the **anonymous device
  bootstrap**. This is the KMS session churn (and the launch-time 500 seen in
  the device log) — every fresh guest install stands up a KMS session.

## ⚠️ P0 open question — resolve before touching auth

`/auth/refresh` is `.AllowAnonymous().RequireSecureChannel()` on the backend, and
`SecureChannelMiddleware` rejects a plain-JSON body (no `X-Syn-Sec-Session`) with
`400 secure_session_required` (except trusted-BFF / test mode). **But the client
refreshes tokens as plain JSON** — `ApiService._refreshSessionToken` posts
`{refreshToken}` via `_refreshDio`, a plain Dio with **no encryption
interceptor**.

So one of these is true, and we must know which before designing guest refresh:
1. **Refresh is silently failing in production** against a channel-enforcing
   backend → users/guests get logged out on access-token expiry (latent bug); or
2. The channel isn't actually enforced on `/auth/refresh` in the live env
   (middleware not wired there, or a config path that skips it); or
3. Refresh is expected to travel the encrypted channel and the client's
   plain-JSON implementation is the bug.

**Action:** confirm against a running stack which case holds (capture a real
`/auth/refresh` response). This decides whether guests need a KMS session *at
all* to stay logged in — the crux of the tiering.

## Tiered model — target

| Tier | Identity | KMS treatment | Can transact |
|------|----------|---------------|--------------|
| **Device-guest** | ephemeral device id | none at launch; ephemeral session key only if a gated call is hit | no store/crypto |
| **Platform-linked** | Game Center / Play Games (silent) | durable subject; session keys on demand | store IAP |
| **Full account** | email / password | full KMS-managed key material | all |

## Phased implementation (safe, independently shippable)

### Phase 0 — resolve the P0 refresh coupling (above). ✅ RESOLVED
Confirmed with the product owner: **guests stay logged in past access-token
expiry, and it is driven by client-side Hive caching** — the auth tokens and
profile/session state persist in Hive and are read back on launch, so the UI
treats the guest as authenticated regardless of live token validity. Login
persistence therefore does **not** depend on the KMS secure channel at all, so
removing the eager pre-warm for guests cannot log them out.

Implication (separate tech-debt, does not block the tiering): because
persistence is cache-backed, the plain-JSON `POST /auth/refresh` is almost
certainly still being **rejected** by the backend's `RequireSecureChannel`
(masked by the cache for read/cached flows). It would surface as a real defect
only on an **authenticated live write after the ~15-min access token expires**
(e.g. progress sync): the call 401s, refresh fails, and the guest silently falls
back to stale cache. Fix in Phase 2.

### Phase 1 — stop eager KMS pre-warm for anonymous guests (client). ✅ DONE
Removed `_ensureSecureSessionForAuthRefresh` from the **anonymous-device**
bootstrap path in `lib/game/providers/auth_providers.dart`; kept it on the
platform-linked / full-account / login paths. Guests now create a KMS session
only if/when they hit a secure-channel-gated endpoint (which `EncryptedApiClient`
establishes on demand). Cuts per-guest KMS session churn and removes the
launch-time handshake (the 500-at-launch source). Auth provider tests green.

### Phase 2 — refresh over the encrypted channel, proactively (Option **B-proactive**, chosen)
Decision: **keep** `/auth/refresh` `RequireSecureChannel` (the backend team treats
it as a first-class secure-channel endpoint — `SecureChannelFilterTests` uses it
as *the* canonical test target), and fix the client to refresh **over** the
encrypted channel, triggered **proactively** while the access token is still
valid. This preserves the security posture and keeps Phase 1 (guests only spin up
a KMS session if active past the refresh threshold, not at launch).

**⚠️ Hazards found while implementing (must be handled — this is why it is a
focused, live-verified refactor, not a one-line change):**

1. **Auto-refresh recursion.** `EncryptedApiClient` and `SecureChannelService`
   both transport over `AuthHttpClient`, which auto-refreshes on expiry. If the
   refresh POST (or the `/security/sessions/start` it needs) goes through that
   same client, it re-enters refresh → infinite recursion. This is exactly why
   the current refresh uses a *separate* non-refreshing transport
   (`ApiService._refreshDio`, `AuthApiClient`'s raw `http.Client`).
2. **DI cycle.** `authApiClient → coreAuth → authHttpClient → secureChannel /
   encryptedApiClient → authHttpClient`. The refresh path cannot simply depend on
   `EncryptedApiClient`.

**Recursion-safe design:**
- Build a dedicated **`AuthHttpClient(coreAuth, tokenStore, autoRefresh: false)`**
  and a dedicated `DefaultSecureChannelService` over it (sharing
  `secureSessionStore`) for the refresh path only. `autoRefresh:false` breaks the
  recursion; late-inject it to break the construction cycle.
- Route `AuthApiClient.refresh()` (and unify `ApiService._refreshSessionToken`)
  through that channel: encrypt `{refreshToken}` → `POST /api/v1/auth/refresh`
  with the secure envelope + `X-Syn-Sec-*` headers → decrypt → reuse
  `AuthApiClient._parseSession` (keeps the nested-`user.id` handling). Confirm the
  request AAD (`method|path|sessionId|seq|subject`) matches what
  `SecureChannelMiddleware.BuildAad` expects for `/api/v1/auth/refresh`.
- **Proactive trigger:** add `AuthSession.isExpiringSoon({lead})` and change
  `AuthHttpClient.send()` from `session.isExpired` → `isExpiringSoon` (refresh at
  ~80% TTL / a few minutes before expiry) so the token is still valid when the
  channel is (re)started, and **renew** (`/security/sessions/renew`) the session
  before its 30-min TTL.
- **Expired-idle edge:** if the app was idle and the token fully expired (no valid
  token to start a channel), fall back to `bootstrapDevice()` re-issue for guests
  / re-login prompt for accounts — never a silent logout.

**Why not shipped from here:** the whole point of B is that the encrypted refresh
handshake actually works end-to-end, which can only be verified against a running
KMS + backend; and it edits the critical auth path (a wrong move logs out every
user). It should land as its own PR validated with a live smoke test, using the
recursion-safe design above. Client unit tests can cover `isExpiringSoon`, the
parse/persist, and that refresh uses the non-refreshing transport.

### Phase 3 — prefer platform identity for the default guest (client)
Lean into the existing `platformLinked` bootstrap
(`gamePlatformService.signInSilently()` → `bootstrapDevice(platform, …)`): try
Game Center / Play Games first, fall back to device-guest only when unavailable.
Gives KMS a durable, recoverable, store-linkable subject. Aligns with store
rules (IAP entitlements need a durable account; Apple Guideline 4.8).

### Phase 4 — KMS keys by tier (backend, `Synaptix.Security.Kms.*`)
Ephemeral guests: session-only ephemeral keys (the ECDH+HKDF handshake already
derives these — no durable per-guest envelope). Provision durable KMS-managed
key material only on promotion to platform-linked / full account. Add a sweep
for expired guest sessions in the session store so it doesn't grow unbounded.

### Phase 5 — promotion flow
On guest → platform/email upgrade, carry progress via the existing account-link
flow and promote the KMS subject in place (session `subjectId` rebinding).

## Not doing
- Removing guest play (hurts the funnel; not required by stores).
- Any auth/refresh code change before Phase 0 is answered.
