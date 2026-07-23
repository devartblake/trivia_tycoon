import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synaptix/core/services/native_platform_service.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';

class FeedbackService {
  static final FeedbackService instance = FeedbackService();

  final NativePlatformService _native;

  FeedbackService({NativePlatformService? native})
      : _native = native ?? NativePlatformService.instance;

  Future<void> haptic(NativeHapticPattern pattern,
      [BuildContext? context]) async {
    SynaptixHapticIntensity? intensity;
    if (context != null) {
      intensity = Theme.of(context).extension<SynaptixTheme>()?.hapticIntensity;
    }

    final handled = await _native.performHaptic(pattern);
    if (handled) return;

    var effectivePattern = pattern;
    if (intensity != null) {
      effectivePattern = _adjustForIntensity(pattern, intensity);
    }

    switch (effectivePattern) {
      case NativeHapticPattern.light:
        await HapticFeedback.lightImpact();
        break;
      case NativeHapticPattern.medium:
      case NativeHapticPattern.success:
      case NativeHapticPattern.warning:
        await HapticFeedback.mediumImpact();
        break;
      case NativeHapticPattern.heavy:
      case NativeHapticPattern.error:
        await HapticFeedback.heavyImpact();
        break;
      case NativeHapticPattern.selection:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  NativeHapticPattern _adjustForIntensity(
      NativeHapticPattern pattern, SynaptixHapticIntensity intensity) {
    if (intensity == SynaptixHapticIntensity.energetic) {
      // Upgrade feedback for high energy
      if (pattern == NativeHapticPattern.selection) {
        return NativeHapticPattern.light;
      }
      if (pattern == NativeHapticPattern.light) {
        return NativeHapticPattern.medium;
      }
      if (pattern == NativeHapticPattern.medium) {
        return NativeHapticPattern.heavy;
      }
      if (pattern == NativeHapticPattern.success) {
        return NativeHapticPattern.heavy;
      }
    } else if (intensity == SynaptixHapticIntensity.soft) {
      // Downgrade feedback for soft mode
      if (pattern == NativeHapticPattern.heavy) {
        return NativeHapticPattern.medium;
      }
      if (pattern == NativeHapticPattern.medium) {
        return NativeHapticPattern.light;
      }
      if (pattern == NativeHapticPattern.light) {
        return NativeHapticPattern.selection;
      }
      if (pattern == NativeHapticPattern.error) {
        return NativeHapticPattern.medium;
      }
    }
    return pattern;
  }
}
