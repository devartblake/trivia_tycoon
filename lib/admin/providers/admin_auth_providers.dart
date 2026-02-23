import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../core/services/settings/app_settings.dart';

/// Canonical admin claims resolved from backend `/admin/auth/me`.
///
/// Returns `{ roles: List<String>, permissions: List<String>, ... }` when available.
final adminClaimsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final serviceManager = ref.read(serviceManagerProvider);

  try {
    final data = await serviceManager.apiService.get('/admin/auth/me');
    return data;
  } catch (_) {
    // Fallback to local profile/settings when backend claims endpoint
    // is unavailable in some environments.
    final profile = ref.read(playerProfileServiceProvider);
    final role = await profile.getUserRole();
    final isAdmin = role == 'admin' || await AppSettings.isAdminUser();
    return {
      'roles': [isAdmin ? 'admin' : (role ?? 'player')],
      'permissions': <String>[],
    };
  }
});

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

