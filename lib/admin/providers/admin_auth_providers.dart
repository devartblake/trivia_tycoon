import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_token_store.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../core/services/settings/app_settings.dart';

/// Canonical admin claims resolved from backend `/admin/auth/me`.
///
/// Returns `{ roles: List<String>, permissions: List<String>, ... }` when available.
final adminClaimsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final serviceManager = ref.read(serviceManagerProvider);
  final tokenStore = ref.read(authTokenStoreProvider);

  try {
    final data = await serviceManager.apiService.get('/admin/auth/me');
    return data;
  } on ApiRequestException catch (e) {
    // If token is stale, try admin refresh flow once then retry claims.
    if (e.statusCode == 401) {
      final refreshed = await _tryAdminRefresh(ref, tokenStore, serviceManager);
      if (refreshed) {
        final retried = await serviceManager.apiService.get('/admin/auth/me');
        return retried;
      }
    }

    return _fallbackClaims(ref);
  } catch (_) {
    // Fallback to local profile/settings when backend claims endpoint
    // is unavailable in some environments.
    return _fallbackClaims(ref);
  }
});

Future<bool> _tryAdminRefresh(
  Ref ref,
  AuthTokenStore tokenStore,
  dynamic serviceManager,
) async {
  final session = tokenStore.load();
  if (session.refreshToken.isEmpty) return false;

  try {
    final deviceIdService = ref.read(deviceIdServiceProvider);
    final deviceIdentity = await deviceIdService.getDeviceIdentityPayload();

    final response = await serviceManager.apiService.post(
      '/admin/auth/refresh',
      body: {
        'refreshToken': session.refreshToken,
        ...deviceIdentity,
      },
    );

    final newAccess =
        response['accessToken']?.toString() ?? response['access_token']?.toString() ?? '';
    if (newAccess.isEmpty) return false;

    final newRefresh = response['refreshToken']?.toString() ??
        response['refresh_token']?.toString() ??
        session.refreshToken;
    final expiresIn = response['expiresIn'];
    DateTime? expiresAt;
    if (expiresIn is int) {
      expiresAt = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    }

    await tokenStore.save(
      session.copyWith(
        accessToken: newAccess,
        refreshToken: newRefresh,
        expiresAtUtc: expiresAt,
      ),
    );

    return true;
  } catch (_) {
    return false;
  }
}

Future<Map<String, dynamic>> _fallbackClaims(Ref ref) async {
  final profile = ref.read(playerProfileServiceProvider);
  final role = await profile.getUserRole();
  final isAdmin = role == 'admin' || await AppSettings.isAdminUser();
  return {
    'roles': [isAdmin ? 'admin' : (role ?? 'player')],
    'permissions': <String>[],
  };
}

/// Unified admin gate sourced from `adminClaimsProvider`.
final unifiedIsAdminProvider = FutureProvider<bool>((ref) async {
  final claims = await ref.watch(adminClaimsProvider.future);

  final dynamic rolesRaw = claims['roles'];
  if (rolesRaw is List) {
    return rolesRaw.any((r) => r.toString().toLowerCase() == 'admin');
  }

  final role = claims['role']?.toString().toLowerCase();
  return role == 'admin';
});
