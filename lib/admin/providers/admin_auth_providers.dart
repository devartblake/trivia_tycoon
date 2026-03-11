import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_token_store.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../core/services/settings/app_settings.dart';
import '../../core/manager/service_manager.dart';

/// Canonical admin claims resolved from backend `/admin/auth/me`.
///
/// Returns `{ roles: List<String>, permissions: List<String>, ... }` when available.
final adminClaimsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final tokenStore = ref.read(authTokenStoreProvider);

  try {
    final data = await apiService.get('/admin/auth/me');
    return data;
  } on ApiRequestException catch (e) {
    // If token is stale, try admin refresh flow once then retry claims.
    if (e.statusCode == 401) {
      final refreshed = await _tryAdminRefresh(ref, tokenStore, apiService);
      if (refreshed) {
        final retried = await apiService.get('/admin/auth/me');
        return retried;
      }
    }

    return _fallbackClaims(ref, tokenStore);
  } catch (_) {
    // Fallback to local profile/settings when backend claims endpoint
    // is unavailable in some environments.
    return _fallbackClaims(ref, tokenStore);
  }
});

Future<bool> _tryAdminRefresh(
  Ref ref,
  AuthTokenStore tokenStore,
  ApiService apiService,
) async {
  final session = tokenStore.load();
  if (session.refreshToken.isEmpty) return false;

  try {
    final deviceIdService = ref.read(deviceIdServiceProvider);
    final deviceIdentity = await deviceIdService.getDeviceIdentityPayload();

    Map<String, dynamic>? response;
    for (final path in const ['/admin/auth/refresh', '/auth/refresh']) {
      try {
        response = await apiService.post(
          path,
          body: {
            'refreshToken': session.refreshToken,
            'refresh_token': session.refreshToken,
            ...deviceIdentity,
          },
        );
        break;
      } on ApiRequestException catch (error) {
        if (error.statusCode == 401 || error.statusCode == 403) {
          await tokenStore.clear();
          return false;
        }
      }
    }

    if (response == null) {
      return false;
    }

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

Future<Map<String, dynamic>> _fallbackClaims(Ref ref, AuthTokenStore tokenStore) async {
  final session = tokenStore.load();
  final storedRoles = session.roles
      .map((role) => role.toLowerCase())
      .where((role) => role.isNotEmpty)
      .toSet()
      .toList(growable: false);

  if (storedRoles.isNotEmpty) {
    return {
      'roles': storedRoles,
      'permissions': session.metadata?['permissions'] is List
          ? (session.metadata?['permissions'] as List)
              .map((permission) => permission.toString())
              .toList(growable: false)
          : <String>[],
    };
  }

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
