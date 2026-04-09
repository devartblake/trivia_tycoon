/// Profile, currency, energy, and referral providers.
///
/// Depends on [core_providers.dart] and [game_providers.dart].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/manager/currency_manager.dart';
import '../../game/controllers/coin_balance_notifier.dart';
import '../../game/controllers/energy_notifier.dart';
import '../../game/controllers/challenge_lives_notifier.dart';
import '../../game/data/referral_repository.dart';
import '../../game/models/currency_type.dart';
import '../../game/models/referral_models.dart';
import '../../game/services/referral_api_service.dart';
import '../../game/services/referral_invite_api_service.dart';
import '../../game/services/referral_invite_service.dart';
import '../../game/services/referral_invite_storage_service.dart';
import '../../game/services/referral_service.dart';
import '../../game/services/referral_storage_service.dart';
import 'core_providers.dart';
import 'game_providers.dart';

// ---------------------------------------------------------------------------
// Currency
// ---------------------------------------------------------------------------

final currencyManagerProvider =
Provider<CurrencyManager>((ref) => CurrencyManager(ref));

final coinBalanceProvider =
StateNotifierProvider<CoinBalanceNotifier, int>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  return CoinBalanceNotifier(storage);
});

final diamondBalanceProvider = Provider<int>((ref) {
  return ref.watch(currencyManagerProvider).getBalance(CurrencyType.diamonds);
});

final coinNotifierProvider = Provider<CurrencyNotifier>((ref) {
  return ref.read(currencyManagerProvider).getNotifier(CurrencyType.coins);
});

final diamondNotifierProvider = Provider<CurrencyNotifier>((ref) {
  return ref.read(currencyManagerProvider).getNotifier(CurrencyType.diamonds);
});

// ---------------------------------------------------------------------------
// Energy / Lives
// ---------------------------------------------------------------------------

final energyProvider =
StateNotifierProvider<EnergyNotifier, EnergyState>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  return EnergyNotifier(storage);
});

final livesProvider =
StateNotifierProvider<ChallengeLivesNotifier, ChallengeLivesState>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  return ChallengeLivesNotifier(storage);
});

final energyRefillTimeProvider = StateProvider<Duration>((ref) {
  final energyState = ref.watch(energyProvider);
  if (energyState.current >= energyState.max) return Duration.zero;
  return kEnergyRefillInterval;
});

// ---------------------------------------------------------------------------
// User profile data
// ---------------------------------------------------------------------------

final recentQuizzesProvider =
FutureProvider<List<Map<String, String>>>((ref) async {
  final quizService = ref.read(quizProgressServiceProvider);
  return quizService.getRecentQuizzes();
});

final userProfileProvider = Provider<Map<String, dynamic>>((ref) {
  final profileService = ref.watch(playerProfileServiceProvider);
  return profileService.getProfile();
});

// ---------------------------------------------------------------------------
// Identity
// ---------------------------------------------------------------------------

final currentUserIdProvider = FutureProvider<String>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final playerProfile = ref.watch(playerProfileServiceProvider);

  final email = await authService.getStoredEmail();
  if (email != null && email.isNotEmpty) {
    return email.split('@').first;
  }

  final playerName = await playerProfile.getPlayerName();
  if (playerName != 'Player') {
    return playerName;
  }

  return 'guest';
});

// ---------------------------------------------------------------------------
// Referral
// ---------------------------------------------------------------------------

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final services = ref.read(serviceManagerProvider);
  return ReferralRepository(
    api: services.apiService,
    cache: services.appCacheService,
  );
});

final referralStorageServiceProvider = Provider<ReferralStorageService>((ref) {
  return ref.watch(serviceManagerProvider).referralStorageService;
});

final referralApiServiceProvider = Provider<ReferralApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReferralApiService(apiService);
});

final referralServiceProvider = Provider<ReferralService>((ref) {
  final storage = ref.watch(referralStorageServiceProvider);
  final api = ref.watch(referralApiServiceProvider);
  return ReferralService(
    storage: storage,
    api: api,
    userId: 'guest',
    baseUrl: 'https://www.trivia.app',
  );
});

final asyncReferralServiceProvider =
FutureProvider<ReferralService>((ref) async {
  final storage = ref.watch(referralStorageServiceProvider);
  final api = ref.watch(referralApiServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);
  return ReferralService(
    storage: storage,
    api: api,
    userId: userId,
    baseUrl: 'https://www.trivia.app',
  );
});

final userReferralCodeProvider = FutureProvider<ReferralCode>((ref) async {
  final referralService =
  await ref.watch(asyncReferralServiceProvider.future);
  return await referralService.getOrCreateReferralCode();
});

final referralStatsProvider =
FutureProvider<Map<String, dynamic>>((ref) async {
  final referralService =
  await ref.watch(asyncReferralServiceProvider.future);
  return await referralService.getStats();
});

// ---------------------------------------------------------------------------
// Referral Invite
// ---------------------------------------------------------------------------

final referralInviteStorageServiceProvider =
FutureProvider<ReferralInviteStorageService>((ref) async {
  final storage = ReferralInviteStorageService();
  await storage.initialize();
  return storage;
});

final referralInviteApiServiceProvider =
Provider<ReferralInviteApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReferralInviteApiService(apiService);
});

final referralInviteServiceProvider = Provider<ReferralInviteService>((ref) {
  final storageAsync = ref.watch(referralInviteStorageServiceProvider);
  final api = ref.watch(referralInviteApiServiceProvider);
  return storageAsync.maybeWhen(
    data: (storage) => ReferralInviteService(
      storage: storage,
      api: api,
      userId: 'guest',
    ),
    orElse: () =>
    throw StateError('ReferralInviteStorageService is not initialized yet.'),
  );
});

final asyncReferralInviteServiceProvider =
FutureProvider<ReferralInviteService>((ref) async {
  final storage =
  await ref.watch(referralInviteStorageServiceProvider.future);
  final api = ref.watch(referralInviteApiServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);
  return ReferralInviteService(
    storage: storage,
    api: api,
    userId: userId,
  );
});

final userInvitesProvider =
FutureProvider<List<ReferralInvite>>((ref) async {
  final service =
  await ref.watch(asyncReferralInviteServiceProvider.future);
  return service.getInvites();
});

final pendingInvitesCountProvider = FutureProvider<int>((ref) async {
  final service =
  await ref.watch(asyncReferralInviteServiceProvider.future);
  return service.getPendingInvites().length;
});

final inviteStatsProvider =
FutureProvider<Map<String, int>>((ref) async {
  final service =
  await ref.watch(asyncReferralInviteServiceProvider.future);
  return service.getStats();
});

final liveInvitesProvider =
StreamProvider.family<List<ReferralInvite>, String>((ref, userId) {
  return Stream.periodic(const Duration(seconds: 5), (_) async {
    final storage =
    await ref.read(referralInviteStorageServiceProvider.future);
    return storage.getUserInvites(userId);
  }).asyncMap((invites) async => invites);
});

final createInviteProvider = Provider<
    Future<ReferralInvite> Function({
    required String referralCode,
    String? inviteeName,
    String? inviteeEmail,
    int expirationDays,
    })>((ref) {
  return ({
    required String referralCode,
    String? inviteeName,
    String? inviteeEmail,
    int expirationDays = 7,
  }) async {
    final service =
    await ref.read(asyncReferralInviteServiceProvider.future);
    return await service.createInvite(
      referralCode: referralCode,
      inviteeName: inviteeName,
      inviteeEmail: inviteeEmail,
      expirationDays: expirationDays,
    );
  };
});

final redeemInviteProvider = Provider<
    Future<bool> Function({
    required String inviteId,
    required String redeemedByUserId,
    String? redeemerName,
    })>((ref) {
  return ({
    required String inviteId,
    required String redeemedByUserId,
    String? redeemerName,
  }) async {
    final service =
    await ref.read(asyncReferralInviteServiceProvider.future);
    return await service.redeemInvite(
      inviteId: inviteId,
      redeemedByUserId: redeemedByUserId,
      redeemerName: redeemerName,
    );
  };
});

// ---------------------------------------------------------------------------
// UI state derived from profile
// ---------------------------------------------------------------------------

final pendingInvitesProvider = Provider<int>((ref) {
  final countAsync = ref.watch(pendingInvitesCountProvider);
  return countAsync.maybeWhen(data: (count) => count, orElse: () => 0);
});
