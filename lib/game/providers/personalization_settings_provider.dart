import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local-only UI preferences for the personalization layer.
///
/// These control display density and explainability copy, not
/// whether the backend runs recommendations (that is [personalizationEnabledProvider]).
class PersonalizationSettings {
  final bool reduceSuggestions;
  final bool showReasons;

  const PersonalizationSettings({
    this.reduceSuggestions = false,
    this.showReasons = true,
  });

  PersonalizationSettings copyWith({
    bool? reduceSuggestions,
    bool? showReasons,
  }) {
    return PersonalizationSettings(
      reduceSuggestions: reduceSuggestions ?? this.reduceSuggestions,
      showReasons: showReasons ?? this.showReasons,
    );
  }
}

class PersonalizationSettingsNotifier
    extends StateNotifier<PersonalizationSettings> {
  PersonalizationSettingsNotifier() : super(const PersonalizationSettings());

  void setReduceSuggestions(bool value) =>
      state = state.copyWith(reduceSuggestions: value);

  void setShowReasons(bool value) =>
      state = state.copyWith(showReasons: value);
}

final personalizationSettingsProvider = StateNotifierProvider<
    PersonalizationSettingsNotifier, PersonalizationSettings>(
  (ref) => PersonalizationSettingsNotifier(),
);
