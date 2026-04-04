import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

/// Lightweight audio cue helper for Synaptix Hub interactions.
///
/// Uses system click sound and respects global audio + sound-effects toggles.
void playHubTapSound(WidgetRef ref) {
  final audioSettings = ref.read(audioSettingsServiceProvider);
  final audioOn = audioSettings.getAudioOn(defaultValue: true);
  final soundsOn = audioSettings.getSoundsOn(defaultValue: true);
  if (!audioOn || !soundsOn) return;

  SystemSound.play(SystemSoundType.click);
}
