import 'package:flutter/services.dart';
import 'package:trivia_tycoon/core/services/native_platform_service.dart';

class FeedbackService {
  static final FeedbackService instance = FeedbackService();

  final NativePlatformService _native;

  FeedbackService({NativePlatformService? native})
      : _native = native ?? NativePlatformService.instance;

  Future<void> haptic(NativeHapticPattern pattern) async {
    final handled = await _native.performHaptic(pattern);
    if (handled) return;

    switch (pattern) {
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
}
