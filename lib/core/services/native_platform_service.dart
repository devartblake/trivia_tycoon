import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum NativeHapticPattern {
  light,
  medium,
  heavy,
  selection,
  success,
  warning,
  error,
}

class NativeDeviceIntegrity {
  final String platform;
  final String packageName;
  final String? installerPackageName;
  final bool isDebuggable;
  final bool isEmulator;
  final int sdkInt;
  final String? manufacturer;
  final String? model;
  final String? fingerprint;
  final String? appVersionName;
  final int? appVersionCode;

  const NativeDeviceIntegrity({
    required this.platform,
    required this.packageName,
    required this.installerPackageName,
    required this.isDebuggable,
    required this.isEmulator,
    required this.sdkInt,
    required this.manufacturer,
    required this.model,
    required this.fingerprint,
    required this.appVersionName,
    required this.appVersionCode,
  });

  factory NativeDeviceIntegrity.fromMap(Map<dynamic, dynamic> map) {
    return NativeDeviceIntegrity(
      platform: (map['platform'] as String?) ?? 'unknown',
      packageName: (map['packageName'] as String?) ?? '',
      installerPackageName: map['installerPackageName'] as String?,
      isDebuggable: (map['isDebuggable'] as bool?) ?? false,
      isEmulator: (map['isEmulator'] as bool?) ?? false,
      sdkInt: (map['sdkInt'] as int?) ?? 0,
      manufacturer: map['manufacturer'] as String?,
      model: map['model'] as String?,
      fingerprint: map['fingerprint'] as String?,
      appVersionName: map['appVersionName'] as String?,
      appVersionCode: map['appVersionCode'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'packageName': packageName,
      'installerPackageName': installerPackageName,
      'isDebuggable': isDebuggable,
      'isEmulator': isEmulator,
      'sdkInt': sdkInt,
      'manufacturer': manufacturer,
      'model': model,
      'fingerprint': fingerprint,
      'appVersionName': appVersionName,
      'appVersionCode': appVersionCode,
    };
  }
}

class NativePlatformService {
  static const channelName = 'trivia_native';
  static final NativePlatformService instance = NativePlatformService();

  final MethodChannel _channel;

  NativePlatformService({
    MethodChannel channel = const MethodChannel(channelName),
  }) : _channel = channel;

  Future<String?> showInputDialog(String title, String message) {
    return _channel.invokeMethod<String>('showInputDialog', {
      'title': title,
      'message': message,
    });
  }

  Future<void> secureSet(String key, String value) async {
    await _channel.invokeMethod<bool>('secureSet', {
      'key': key,
      'value': value,
    });
  }

  Future<String?> secureGet(String key) {
    return _channel.invokeMethod<String>('secureGet', {'key': key});
  }

  Future<void> secureDelete(String key) async {
    await _channel.invokeMethod<bool>('secureDelete', {'key': key});
  }

  Future<void> secureClear() async {
    await _channel.invokeMethod<bool>('secureClear');
  }

  Future<NativeDeviceIntegrity> getDeviceIntegrity() async {
    final raw = await _channel.invokeMapMethod<String, dynamic>(
      'getDeviceIntegrity',
    );
    return NativeDeviceIntegrity.fromMap(raw ?? const {});
  }

  Future<bool> performHaptic(NativeHapticPattern pattern) async {
    if (kIsWeb) return false;

    try {
      return await _channel.invokeMethod<bool>('performHaptic', {
            'pattern': pattern.name,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> openAndroidNotificationSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>(
            'openAndroidNotificationSettings',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
