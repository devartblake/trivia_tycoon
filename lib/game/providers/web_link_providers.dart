import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/env.dart';
import '../../core/services/web_link_service.dart';
import 'core_providers.dart';

/// Provides the [WebLinkService] wired to the app's HTTP client and backend URL.
///
/// The access token getter reads from [coreAuthServiceProvider] at call-time
/// so it always returns the current token without creating stale captures.
final webLinkServiceProvider = Provider<WebLinkService>((ref) {
  final authService = ref.watch(coreAuthServiceProvider);

  return WebLinkService(
    httpClient: http.Client(),
    apiBaseUrl: EnvConfig.apiV1BaseUrl,
    accessTokenGetter: () => authService.accessToken,
  );
});
