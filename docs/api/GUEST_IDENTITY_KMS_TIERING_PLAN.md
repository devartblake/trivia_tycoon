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
expiry.** Since the client refreshes/re-bootstraps over plain JSON (which does
not use the secure channel), the eager KMS pre-warm is **not** what keeps a
guest authenticated — so removing it for guests cannot log them out. (The
`/auth/refresh` `RequireSecureChannel` vs plain-JSON-client inconsistency is
noted as separate tech-debt: either the channel isn't enforced on refresh in
the live env, or persistence relies on re-bootstrap; worth a follow-up, but it
does not block the tiering.)

### Phase 1 — stop eager KMS pre-warm for anonymous guests (client). ✅ DONE
Removed `_ensureSecureSessionForAuthRefresh` from the **anonymous-device**
bootstrap path in `lib/game/providers/auth_providers.dart`; kept it on the
platform-linked / full-account / login paths. Guests now create a KMS session
only if/when they hit a secure-channel-gated endpoint (which `EncryptedApiClient`
establishes on demand). Cuts per-guest KMS session churn and removes the
launch-time handshake (the 500-at-launch source). Auth provider tests green.

### Phase 2 — decouple guest token refresh from the channel (backend + client)
Depending on Phase 0: either give device-guest tokens a refresh path that does
not require the secure channel (keep channel-bound refresh for elevated
sessions only), or fix the client to refresh over the encrypted channel. This is
the change that lets guests stay logged in without a standing KMS session.

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
