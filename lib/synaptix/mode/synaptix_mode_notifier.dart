import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'synaptix_mode.dart';

/// StateNotifier that manages the active [SynaptixMode].
///
/// Handles age-group-to-mode mapping and persists the mode to Hive
/// via [PlayerProfileService].
class SynaptixModeNotifier extends StateNotifier<SynaptixMode> {
  final PlayerProfileService _profileService;

  SynaptixModeNotifier(this._profileService) : super(SynaptixMode.teen);

  /// Explicitly set the mode and persist.
  Future<void> setMode(SynaptixMode mode) async {
    state = mode;
    await _profileService.saveSynaptixMode(mode.name);
  }

  /// Derive the mode from a saved age-group string.
  void deriveFromAgeGroup(String ageGroup) {
    state = mapAgeGroupToMode(ageGroup);
  }

  /// Pure mapping from age-group string to [SynaptixMode].
  static SynaptixMode mapAgeGroupToMode(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'kids':
      case 'child':
      case 'children':
      case 'elementary':
      case 'k-5':
        return SynaptixMode.kids;
      case 'teen':
      case 'teens':
      case 'middle':
      case 'middle school':
        return SynaptixMode.teen;
      default:
        return SynaptixMode.adult;
    }
  }
}
