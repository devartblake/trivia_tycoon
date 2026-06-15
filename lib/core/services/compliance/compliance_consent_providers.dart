import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../env.dart';
import '../../../game/providers/core_providers.dart';
import 'compliance_consent_api_client.dart';

/// Client for the Synaptix.Compliance.Api (age verification, consent, parental
/// consent, privacy requests). Always available — defaults to the main API host
/// when `COMPLIANCE_CONSENT_SERVICE_URL` is not set (routes live at
/// `/compliance/...`).
final complianceConsentApiClientProvider =
    Provider<ComplianceConsentApiClient>((ref) {
  final tokenStore = ref.watch(authTokenStoreProvider);
  final client = ComplianceConsentApiClient(
    http.Client(),
    baseUrl: EnvConfig.complianceConsentServiceUrl,
    accessTokenProvider: () => tokenStore.load().accessToken,
  );
  return client;
});
