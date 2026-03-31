import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import '../../core/services/storage/app_cache_service.dart';
import '../models/referral_models.dart';
import '../utils/referral_code_gen.dart';

class ReferralRepository {
  final AppCacheService cache;
  final ApiService api;

  ReferralRepository({
    required this.cache,
    required this.api,
  });

  Future<ReferralCode> generateReferralCode(String ownerUserId) async {
    // Try server-side generation first
    try {
      // FIX: Ensure the API response is correctly cast to a Map.
      final serverResponse =
      await api.post('/referrals', body: {'owner_user_id': ownerUserId});

      final code = ReferralCode.fromJson({
        'code': serverResponse['code'],
        'ownerUserId': ownerUserId,
        'createdAt': serverResponse['created_at'],
        'expiresAt': serverResponse['expires_at'],
        'status': serverResponse['status'],
        'isSynced': true,
        'serverId': serverResponse['id']?.toString(),
      });

      // FIX: Use the simplified `setJson` method for reliable caching.
      await cache.setJson('cache.referral.currentCode', code.toJson());
      return code;
    } on ApiRequestException catch (e) {
      // ApiService wraps all network/HTTP errors into ApiRequestException before surfacing
      // them — catching DioException here would never fire. Use ApiRequestException for
      // the offline fallback so the intent is clear and the import on dio is not needed.
      LogManager.debug('API error generating referral code: $e. Falling back to local generation.');
      return _generateLocalCode(ownerUserId);
    } catch (e) {
      LogManager.debug('Unexpected error generating referral code: $e. Falling back to local generation.');
      return _generateLocalCode(ownerUserId);
    }
  }

  /// Generates a local, unsynced referral code as a fallback.
  Future<ReferralCode> _generateLocalCode(String ownerUserId) async {
    final localCode = ReferralCode(
      code: ReferralCodeGen.generate(),
      ownerUserId: ownerUserId,
      createdAt: DateTime.now().toUtc(),
      isSynced: false,
    );
    await cache.setJson('cache.referral.currentCode', localCode.toJson());
    return localCode;
  }
}
