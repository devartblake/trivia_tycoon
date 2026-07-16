import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/native_platform_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('trivia_native_test');
  final service = NativePlatformService(channel: channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('secureSet, secureGet, and secureDelete call native channel', () async {
    final calls = <MethodCall>[];

    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'secureGet') return 'stored-value';
      return true;
    });

    await service.secureSet('device_id', 'abc');
    final value = await service.secureGet('device_id');
    await service.secureDelete('device_id');

    expect(value, 'stored-value');
    expect(calls.map((call) => call.method), [
      'secureSet',
      'secureGet',
      'secureDelete',
    ]);
    expect(calls.first.arguments, {
      'key': 'device_id',
      'value': 'abc',
    });
  });

  test('getDeviceIntegrity parses native payload', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getDeviceIntegrity');
      return {
        'platform': 'android',
        'packageName': 'com.example.app',
        'installerPackageName': 'com.android.vending',
        'isDebuggable': true,
        'isEmulator': false,
        'sdkInt': 36,
        'manufacturer': 'Google',
        'model': 'Pixel',
        'fingerprint': 'fingerprint',
        'appVersionName': '1.0',
        'appVersionCode': 7,
      };
    });

    final integrity = await service.getDeviceIntegrity();

    expect(integrity.platform, 'android');
    expect(integrity.packageName, 'com.example.app');
    expect(integrity.installerPackageName, 'com.android.vending');
    expect(integrity.isDebuggable, isTrue);
    expect(integrity.sdkInt, 36);
    expect(integrity.appVersionCode, 7);
  });

  test('performHaptic returns false when native channel fails', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'NO_VIBRATOR');
    });

    final handled = await service.performHaptic(NativeHapticPattern.medium);

    expect(handled, isFalse);
  });

  test('showInputDialog preserves existing native method', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'showInputDialog');
      expect(call.arguments, {
        'title': 'Name',
        'message': 'Enter name',
      });
      return 'Alex';
    });

    final response = await service.showInputDialog('Name', 'Enter name');

    expect(response, 'Alex');
  });
}
