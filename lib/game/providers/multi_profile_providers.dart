import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/quiz_results_provider.dart';
import '../../core/services/settings/multi_profile_service.dart';
import '../../core/services/settings/player_profile_service.dart';
import '../services/profile_service.dart';

// Provider for the multi-profile service
final multiProfileServiceProvider = Provider<MultiProfileService>((ref) {
  return MultiProfileService();
});

// Provider for all profiles
final profilesProvider = FutureProvider<List<ProfileData>>((ref) async {
  final service = ref.read(multiProfileServiceProvider);
  return await service.getAllProfiles();
});

// Provider for the currently active profile
final activeProfileProvider = FutureProvider<ProfileData?>((ref) async {
  final service = ref.read(multiProfileServiceProvider);
  return await service.getActiveProfile();
});

// Provider for active profile state (can be used synchronously after initial load)
final activeProfileStateProvider = StateProvider<ProfileData?>((ref) => null);

// Provider that bridges the multi-profile system with your existing ProfileService
final bridgedProfileServiceProvider = Provider<ProfileService>((ref) {
  final activeProfile = ref.watch(activeProfileStateProvider);

  if (activeProfile == null) {
    // Fallback to default profile service
    return ProfileService(
      ref,
      playerId: 'local-guest',
      displayName: 'Guest',
    );
  }

  return ProfileService(
    ref,
    playerId: activeProfile.id,
    displayName: activeProfile.name,
    unlockedCategories: _extractUnlockedCategories(activeProfile),
    preferences: activeProfile.preferences,
  );
});

// Helper function to extract unlocked categories from profile game stats
Set<String> _extractUnlockedCategories(ProfileData profile) {
  final gameStats = profile.gameStats;
  final unlockedCats = gameStats['unlockedCategories'];

  if (unlockedCats is List) {
    return Set<String>.from(unlockedCats);
  } else if (unlockedCats is Set) {
    return Set<String>.from(unlockedCats);
  }

  return <String>{};
}

// Provider for profile stats that automatically updates when active profile changes
final activeProfileStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final activeProfile = ref.watch(activeProfileStateProvider);

  if (activeProfile == null) {
    return {
      'level': 1,
      'currentXP': 0,
      'maxXP': 500,
      'rank': 'Trivia Novice',
      'totalQuizzes': 0,
      'correctAnswers': 0,
      'currentStreak': 0,
      'averageScore': 0.0,
    };
  }

  final gameStats = activeProfile.gameStats;

  return {
    'level': activeProfile.level,
    'currentXP': activeProfile.currentXP,
    'maxXP': activeProfile.maxXP,
    'rank': activeProfile.rank,
    'totalQuizzes': gameStats['totalQuizzes'] ?? 0,
    'correctAnswers': gameStats['correctAnswers'] ?? 0,
    'currentStreak': gameStats['currentStreak'] ?? 0,
    'averageScore': gameStats['averageScore'] ?? 0.0,
    'lastPlayed': gameStats['lastPlayed'],
    'favoriteCategory': gameStats['favoriteCategory'],
  };
});

// Provider for XP that syncs with the active profile
final profileAwareXPProvider = StateNotifierProvider<ProfileAwareXPNotifier, int>((ref) {
  return ProfileAwareXPNotifier(ref);
});

class ProfileAwareXPNotifier extends StateNotifier<int> {
  final Ref ref;

  ProfileAwareXPNotifier(this.ref) : super(0) {
    _initializeXP();
  }

  void _initializeXP() {
    final activeProfile = ref.read(activeProfileStateProvider);
    if (activeProfile != null) {
      state = activeProfile.currentXP;
    }
  }

  Future<void> addXP(int amount) async {
    final multiProfileService = ref.read(multiProfileServiceProvider);
    final result = await multiProfileService.addXPToActiveProfile(amount);

    if (!result.containsKey('error')) {
      state = result['newXP'] ?? state;

      // Update the active profile state
      final activeProfile = ref.read(activeProfileStateProvider);
      if (activeProfile != null) {
        final updatedProfile = activeProfile.copyWith(
          currentXP: result['newXP'],
          level: result['newLevel'],
          maxXP: result['newMaxXP'],
        );
        ref.read(activeProfileStateProvider.notifier).state = updatedProfile;
      }
    }
  }

  void setXP(int xp) {
    state = xp;
  }
}

// Provider that manages profile initialization and switching
final profileManagerProvider = StateNotifierProvider<ProfileManagerNotifier, ProfileManagerState>((ref) {
  return ProfileManagerNotifier(ref);
});

class ProfileManagerState {
  final bool isInitialized;
  final bool isLoading;
  final String? error;
  final List<ProfileData> profiles;
  final ProfileData? activeProfile;

  const ProfileManagerState({
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
    this.profiles = const [],
    this.activeProfile,
  });

  ProfileManagerState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? error,
    List<ProfileData>? profiles,
    ProfileData? activeProfile,
  }) {
    return ProfileManagerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profiles: profiles ?? this.profiles,
      activeProfile: activeProfile ?? this.activeProfile,
    );
  }
}

class ProfileManagerNotifier extends StateNotifier<ProfileManagerState> {
  final Ref ref;

  ProfileManagerNotifier(this.ref) : super(const ProfileManagerState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      final multiProfileService = ref.read(multiProfileServiceProvider);
      final legacyService = PlayerProfileService();

      // Initialize and migrate from legacy service if needed
      await multiProfileService.initializeAndMigrate(legacyService);

      // Load all profiles
      final profiles = await multiProfileService.getAllProfiles();
      final activeProfile = await multiProfileService.getActiveProfile();

      // Update the active profile state provider
      ref.read(activeProfileStateProvider.notifier).state = activeProfile;

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        profiles: profiles,
        activeProfile: activeProfile,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> switchProfile(String profileId) async {
    state = state.copyWith(isLoading: true);

    try {
      final multiProfileService = ref.read(multiProfileServiceProvider);
      final success = await multiProfileService.setActiveProfile(profileId);

      if (success) {
        final activeProfile = await multiProfileService.getActiveProfile();

        // Update the active profile state provider
        ref.read(activeProfileStateProvider.notifier).state = activeProfile;

        // Update XP provider
        if (activeProfile != null) {
          ref.read(profileAwareXPProvider.notifier).setXP(activeProfile.currentXP);
        }

        state = state.copyWith(
          isLoading: false,
          activeProfile: activeProfile,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to switch profile',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshProfiles() async {
    try {
      final multiProfileService = ref.read(multiProfileServiceProvider);
      final profiles = await multiProfileService.getAllProfiles();
      final activeProfile = await multiProfileService.getActiveProfile();

      ref.read(activeProfileStateProvider.notifier).state = activeProfile;

      state = state.copyWith(
        profiles: profiles,
        activeProfile: activeProfile,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<ProfileData?> createProfile({
    required String name,
    String? avatar,
    String? country,
    String? ageGroup,
  }) async {
    try {
      final multiProfileService = ref.read(multiProfileServiceProvider);
      final newProfile = await multiProfileService.createProfile(
        name: name,
        avatar: avatar,
        country: country,
        ageGroup: ageGroup,
      );

      if (newProfile != null) {
        await refreshProfiles();
      }

      return newProfile;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> deleteProfile(String profileId) async {
    try {
      final multiProfileService = ref.read(multiProfileServiceProvider);
      final success = await multiProfileService.deleteProfile(profileId);

      if (success) {
        await refreshProfiles();
      }

      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> updateActiveProfileGameStats(Map<String, dynamic> stats) async {
    try {
      final multiProfileService = ref.read(multiProfileServiceProvider);
      await multiProfileService.updateActiveProfileGameStats(stats);
      await refreshProfiles();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Extension to help with profile-aware quiz results
extension ProfileAwareQuizResults on QuizResults {
  Future<void> saveToActiveProfile(WidgetRef ref) async {
    final profileManager = ref.read(profileManagerProvider.notifier);

    // Update game stats
    await profileManager.updateActiveProfileGameStats({
      'lastQuizScore': score,
      'lastQuizXP': totalXP,
      'lastQuizCategory': category,
      'lastPlayed': DateTime.now().toIso8601String(),
      'totalQuizzes': 1, // This would be incremented, not set to 1
    });

    // Add XP to profile
    if (totalXP > 0) {
      await ref.read(profileAwareXPProvider.notifier).addXP(totalXP);
    }
  }
}
