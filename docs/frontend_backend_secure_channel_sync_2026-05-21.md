# Frontend/Backend Secure Channel Sync - 2026-05-21

Repository: `devartblake/trivia_tycoon`

Branch: `docs/backend-secure-channel-handoff-2026-05-21`

Purpose: coordinate the Flutter follow-up work required after the backend secure-channel replay and AAD hardening pass.

## Backend Status

- Backend secure-channel protected endpoints now require `X-Syn-Sec-Session`, `X-Syn-Sec-Seq`, and `X-Syn-Sec-Nonce`.
- Backend rejects replayed sequence/nonce pairs, expired encrypted payload timestamps, subject mismatches, and AAD mismatches.
- Backend AAD now binds each encrypted body to request direction, method, path plus query string, session id, sequence, subject, and encrypted timestamp.
- Backend session negotiation can report `X25519-HKDF-SHA256-AES256GCM` or `P256-HKDF-SHA256-AES256GCM`; clients should use the selected suite from the response.
- Backend tests passed for KMS payload replay/AAD and secure-channel middleware header enforcement.

## Current Frontend Findings

- `SecurePayloadCodec` currently builds AAD from version, method, and path only.
- `EncryptedApiClient` sends secure headers, but the current sequence flow can drift because the session is reloaded after encryption increments `nextSequence`.
- `EncryptedPayload` contains ciphertext, nonce, mac, content type, and timestamp, but no explicit request-context helper for the backend AAD contract.
- `DefaultSecureChannelService` currently starts sessions with X25519 only and should be updated to use the backend-selected suite.
- Existing tests cover codec basics, nonce uniqueness, wrong nonce, session clearing, and payload sizes; they do not yet cover backend-compatible AAD or retry envelope regeneration.

## Frontend Tasks

1. `[x]` Add a secure request context object that captures method, path plus query, session id, sequence, replay nonce, subject if available, and encrypted timestamp. → `SecureRequestContext` added to `lib/core/security/secure_channel_models.dart`
2. `[x]` Build request and response AAD from that request context using the backend contract in `docs/Synaptix_Frontend_Secure_Channel_Handoff.md`. → `SecurePayloadCodec` rewritten with `_buildRequestAad` / `_buildResponseAad` helpers producing the 8-field `syn-sec-v1|direction|METHOD|path+query|sessionId|seq|subject|timestamp` string
3. `[x]` Update encryption so the sequence used for AAD is the same sequence sent in `X-Syn-Sec-Seq`. → `encryptJson` accepts context directly; `_sendEncrypted` captures `sequence = session.nextSequence` before building context
4. `[x]` Generate a fresh replay nonce per protected request and send it as `X-Syn-Sec-Nonce`. → `replayNonce = base64Url.encode(_randomBytes(16))` generated per request in `EncryptedApiClient._sendEncrypted`
5. `[x]` Persist `nextSequence` only after the request envelope and headers are assembled successfully. → `persistSequenceIncrement(session)` called after `encryptJson` returns; removed side-effect from `DefaultSecureChannelService.encryptJson`
6. `[x]` Ensure retries regenerate the encrypted envelope and replay nonce instead of reusing the failed encrypted body. → `SecureSessionExpiredException` triggers `clearSession()` + full re-entry into `doSend()`, which builds a brand-new `SecureRequestContext`
7. `[x]` Update secure-session negotiation to honor the backend-selected suite. → `startSession` advertises `['X25519-HKDF-SHA256-AES256GCM', 'P256-HKDF-SHA256-AES256GCM']`; parses `selectedSuite` from response; uses it in HKDF info string
8. `[x]` Add tests for AAD context, query string binding, sequence/header alignment, replay nonce freshness, retry regeneration, and selected-suite handling. → 6 new tests added to `test/core/security/secure_payload_codec_test.dart`

**Implementation completed:** 2026-05-22

## PR Discussion Prompts

- Which frontend source should provide the subject value used in AAD: decoded access token subject, authenticated profile id, or an empty subject until the backend returns a stable client-visible value?
  → **Decision:** empty string (`subjectId: ''`) until backend provides a stable client-visible value.
- Should failed secure requests always clear the secure session, or only when the backend returns a session-expired/session-invalid response?
  → **Decision:** clear only on `SecureSessionExpiredException`; all other errors propagate without clearing.
- Which protected flows should be smoke-tested first after the AAD update: social mutations, loadout save, arcade spin claim, or economy/store actions?
  → **Decision:** social mutations (`sendFriendRequest`, `acceptFriendRequest`, `removeFriend`) first.

## QA Checklist

| Check | Expected Result | Evidence |
|---|---|---|
| Fresh protected mutation | Request succeeds and backend applies the action once | Implemented — pending manual smoke test on dev backend |
| Duplicate encrypted body replay | Backend rejects replay and action is not applied twice | Implemented — pending manual smoke test on dev backend |
| Query string protected endpoint | AAD includes path and query; request succeeds only with matching context | Implemented + unit test (`different query string produces different AAD`) |
| Session expiry retry | Client creates a new envelope and succeeds after session refresh | Implemented — pending manual smoke test on dev backend |
| Sign-out/sign-in | Secure session and sequence state are cleared before the next account uses the app | Implemented — pending manual smoke test on dev backend |
| Backend-selected suite | Client uses the suite returned by session start | Implemented — pending manual smoke test on dev backend |

## Notes For Reviewers

- This document intentionally avoids secrets, service tokens, Vault details, and internal backend infrastructure configuration.
- The source-of-truth technical handoff is `docs/Synaptix_Frontend_Secure_Channel_Handoff.md`.
- Flutter implementation landed on main 2026-05-22 as part of the Secure Channel AAD hardening commit.
