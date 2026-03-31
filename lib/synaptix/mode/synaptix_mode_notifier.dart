import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import '../../game/analytics/services/analytics_service.dart';
import 'synaptix_mode.dart';

/// StateNotifier that manages the active [SynaptixMode].
///
/// Handles age-group-to-mode mapping and persists the mode to Hive
/// via [PlayerProfileService].
class SynaptixModeNotifier extends StateNotifier<SynaptixMode> {
  final PlayerProfileService _profileService;
  AnalyticsService? _analyticsService;

  SynaptixModeNotifier(this._profileService) : super(SynaptixMode.teen);

  /// Inject analytics service for event tracking.
  void setAnalyticsService(AnalyticsService service) {
    _analyticsService = service;
  }

  /// Explicitly set the mode and persist.
  Future<void> setMode(SynaptixMode mode) async {
    final previous = state;
    state = mode;
    await _profileService.saveSynaptixMode(mode.name);
    _analyticsService?.trackEvent('synaptix_mode_changed', {
      'previous_mode': previous.name,
      'new_mode': mode.name,
      'trigger': 'explicit',
    });
  }

  /// Derive the mode from a saved age-group string.
  void deriveFromAgeGroup(String ageGroup) {
    final previous = state;
    state = mapAgeGroupToMode(ageGroup);
    _analyticsService?.trackEvent('synaptix_mode_mapped', {
      'age_group': ageGroup,
      'mapped_mode': state.name,
      'previous_mode': previous.name,
      'trigger': 'onboarding',
    });
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
