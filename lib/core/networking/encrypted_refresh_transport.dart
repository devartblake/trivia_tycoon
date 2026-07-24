/// Minimal seam for sending an encrypted POST over the KMS secure channel,
/// used by the token-refresh path so it can satisfy the backend's
/// `RequireSecureChannel` on `/auth/refresh` without depending on the concrete
/// [EncryptedApiClient] (which would create a layering/DI cycle) and so it can
/// be faked in unit tests.
///
/// The refresh path must be wired to an instance backed by a **non
/// auto-refreshing** transport — see the recursion hazard in
/// `docs/api/GUEST_IDENTITY_KMS_TIERING_PLAN.md` (Phase 2, Option B-proactive).
abstract class EncryptedRefreshTransport {
  Future<Map<String, dynamic>> postEncrypted(
    String path, {
    required Map<String, dynamic> body,
  });
}
