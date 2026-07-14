import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/core/models/app_config.dart';
import 'package:synaptix/game/providers/core_providers.dart';

/// Fetches /api/v1/app/config from the backend.
///
/// Falls back to [AppConfig.defaultAlpha] on any error so the app is always
/// in a known safe state — only core features enabled — when the backend is
/// unreachable or returns an unexpected response.
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final json = await api.fetchAppConfig();
    if (json.isEmpty) return AppConfig.defaultAlpha;
    return AppConfig.fromJson(json);
  } catch (_) {
    return AppConfig.defaultAlpha;
  }
});

/// Synchronous view of the current feature flags.
///
/// Returns [FeatureFlags.defaultAlpha] while [appConfigProvider] is loading
/// or has errored. This means disabled features remain blocked even on the
/// first frame — the safe default is always closed, not open.
final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return ref.watch(appConfigProvider).maybeWhen(
        data: (config) => config.features,
        orElse: () => FeatureFlags.defaultAlpha,
      );
});
