import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform type enum
enum AppPlatform {
  mobile,   // iOS / Android
  web,      // Web browser
}

/// Platform configuration
class PlatformConfig {
  final AppPlatform platform;
  final bool isMobile;
  final bool isWeb;

  PlatformConfig({required this.platform})
      : isMobile = platform == AppPlatform.mobile,
        isWeb = platform == AppPlatform.web;

  /// Get platform name
  String get name => platform == AppPlatform.mobile ? 'mobile' : 'web';

  /// Check if running on mobile
  bool get onMobile => isMobile;

  /// Check if running on web
  bool get onWeb => isWeb;

  @override
  String toString() => 'PlatformConfig(platform: $name)';
}

/// Platform provider - initialized with platform type
final platformConfigProvider = Provider<PlatformConfig>((ref) {
  throw UnimplementedError(
    'platformConfigProvider must be overridden in main.dart or main_web.dart',
  );
});

/// Convenient getters for platform checks
final isMobileProvider = Provider<bool>((ref) {
  return ref.watch(platformConfigProvider).isMobile;
});

final isWebProvider = Provider<bool>((ref) {
  return ref.watch(platformConfigProvider).isWeb;
});
