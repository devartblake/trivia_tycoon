import '../services/settings/player_profile_service.dart';

/// Extension methods to add missing functionality to PlayerProfileService
/// without modifying the original service file
extension PlayerProfileServiceExtensions on PlayerProfileService {

  /// Loads user profile data (combination of existing methods)
  /// This provides the missing loadUserProfile() method that was referenced in TODOs
  Future<UserProfile> loadUserProfile() async {
    final playerName = await getPlayerName();
    final userRole = await getUserRole();
    final userRoles = await getUserRoles();
    final isPremium = await isPremiumUser();
    final country = await getCountry();
    final ageGroup = await getAgeGroup();
    final avatar = await getAvatar();

    return UserProfile(
      playerName: playerName,
      userRole: userRole,
      userRoles: userRoles,
      isPremium: isPremium,
      country: country,
      ageGroup: ageGroup,
      avatar: avatar,
    );
  }

  /// Checks if the user has completed basic profile setup
  /// Returns true if both name and avatar are set
  Future<bool> hasCompletedBasicProfile() async {
    final playerName = await getPlayerName();
    final avatar = await getAvatar();

    // Consider profile complete if user has more than default name and has avatar
    return playerName != 'Player' && avatar != null && avatar.isNotEmpty;
  }

  /// Saves a complete user profile in one operation
  Future<void> saveCompleteProfile({
    required String playerName,
    String? avatar,
    String? userRole,
    List<String>? userRoles,
    bool? isPremium,
    String? country,
    String? ageGroup,
  }) async {
    await savePlayerName(playerName);

    if (avatar != null) await saveAvatar(avatar);
    if (userRole != null) await saveUserRole(userRole);
    if (userRoles != null) await saveUserRoles(userRoles);
    if (isPremium != null) await setPremiumStatus(isPremium);
    if (country != null) await saveCountry(country);
    if (ageGroup != null) await saveAgeGroup(ageGroup);
  }

  /// Updates only the onboarding-related profile fields
  Future<void> saveOnboardingProfile({
    required String playerName,
    required String avatar,
  }) async {
    await savePlayerName(playerName);
    await saveAvatar(avatar);
  }
}

/// Data class to represent a complete user profile
class UserProfile {
  final String playerName;
  final String? userRole;
  final List<String> userRoles;
  final bool isPremium;
  final String? country;
  final String? ageGroup;
  final String? avatar;

  const UserProfile({
    required this.playerName,
    this.userRole,
    this.userRoles = const [],
    this.isPremium = false,
    this.country,
    this.ageGroup,
    this.avatar,
  });

  /// Check if this is a default/empty profile
  bool get isDefaultProfile => playerName == 'Player' && (avatar == null || avatar!.isEmpty);

  /// Check if user has admin privileges
  bool get isAdmin => userRole == 'admin' || userRoles.contains('admin');

  /// Get display name (falls back to email prefix if available)
  String get displayName => playerName.isNotEmpty ? playerName : 'Player';

  @override
  String toString() {
    return 'UserProfile(name: $playerName, role: $userRole, premium: $isPremium)';
  }
}
