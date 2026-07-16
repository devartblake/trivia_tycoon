import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/leaderboard_filter_settings.dart';

Map<String, dynamic> _baseJson({
  bool showVerifiedOnly = false,
  bool showPremiumOnly = false,
  bool showPowerUsersOnly = false,
  bool excludeBots = false,
  String? deviceType,
  String? notificationPreference,
}) =>
    {
      'showVerifiedOnly': showVerifiedOnly,
      'showPremiumOnly': showPremiumOnly,
      'showPowerUsersOnly': showPowerUsersOnly,
      'excludeBots': excludeBots,
      if (deviceType != null) 'deviceType': deviceType,
      if (notificationPreference != null)
        'notificationPreference': notificationPreference,
    };

void main() {
  // -------------------------------------------------------------------------
  // LeaderboardFilterSettings.fromJson — defaults
  // -------------------------------------------------------------------------

  group('LeaderboardFilterSettings.fromJson — defaults', () {
    test('all booleans default to false when absent', () {
      final settings = LeaderboardFilterSettings.fromJson({});
      expect(settings.showVerifiedOnly, isFalse);
      expect(settings.showPremiumOnly, isFalse);
      expect(settings.showPowerUsersOnly, isFalse);
      expect(settings.excludeBots, isFalse);
    });

    test('deviceType is null when absent', () {
      expect(LeaderboardFilterSettings.fromJson({}).deviceType, isNull);
    });

    test('notificationPreference is null when absent', () {
      expect(LeaderboardFilterSettings.fromJson({}).notificationPreference,
          isNull);
    });
  });

  // -------------------------------------------------------------------------
  // LeaderboardFilterSettings.fromJson — scalar fields
  // -------------------------------------------------------------------------

  group('LeaderboardFilterSettings.fromJson — scalar fields', () {
    test('parses showVerifiedOnly', () {
      expect(
          LeaderboardFilterSettings.fromJson(_baseJson(showVerifiedOnly: true))
              .showVerifiedOnly,
          isTrue);
    });

    test('parses showPremiumOnly', () {
      expect(
          LeaderboardFilterSettings.fromJson(_baseJson(showPremiumOnly: true))
              .showPremiumOnly,
          isTrue);
    });

    test('parses showPowerUsersOnly', () {
      expect(
          LeaderboardFilterSettings.fromJson(
                  _baseJson(showPowerUsersOnly: true))
              .showPowerUsersOnly,
          isTrue);
    });

    test('parses excludeBots', () {
      expect(
          LeaderboardFilterSettings.fromJson(_baseJson(excludeBots: true))
              .excludeBots,
          isTrue);
    });

    test('parses deviceType', () {
      expect(
          LeaderboardFilterSettings.fromJson(_baseJson(deviceType: 'mobile'))
              .deviceType,
          'mobile');
    });

    test('parses notificationPreference', () {
      expect(
          LeaderboardFilterSettings.fromJson(
                  _baseJson(notificationPreference: 'push'))
              .notificationPreference,
          'push');
    });
  });

  // -------------------------------------------------------------------------
  // LeaderboardFilterSettings.toJson
  // -------------------------------------------------------------------------

  group('LeaderboardFilterSettings.toJson', () {
    test('serializes all boolean fields', () {
      final settings = LeaderboardFilterSettings(
        showVerifiedOnly: true,
        showPremiumOnly: true,
        showPowerUsersOnly: true,
        excludeBots: true,
      );
      final json = settings.toJson();
      expect(json['showVerifiedOnly'], isTrue);
      expect(json['showPremiumOnly'], isTrue);
      expect(json['showPowerUsersOnly'], isTrue);
      expect(json['excludeBots'], isTrue);
    });

    test('serializes deviceType', () {
      final settings = LeaderboardFilterSettings(deviceType: 'tablet');
      expect(settings.toJson()['deviceType'], 'tablet');
    });

    test('round-trip preserves all fields', () {
      final original = LeaderboardFilterSettings(
        showVerifiedOnly: true,
        excludeBots: true,
        deviceType: 'desktop',
        notificationPreference: 'email',
      );
      final restored = LeaderboardFilterSettings.fromJson(original.toJson());
      expect(restored.showVerifiedOnly, original.showVerifiedOnly);
      expect(restored.excludeBots, original.excludeBots);
      expect(restored.deviceType, original.deviceType);
      expect(restored.notificationPreference, original.notificationPreference);
    });
  });

  // -------------------------------------------------------------------------
  // LeaderboardFilterSettings.copyWith
  // -------------------------------------------------------------------------

  group('LeaderboardFilterSettings.copyWith', () {
    late LeaderboardFilterSettings base;
    setUp(() => base = LeaderboardFilterSettings.fromJson(_baseJson()));

    test('copies showVerifiedOnly', () {
      expect(base.copyWith(showVerifiedOnly: true).showVerifiedOnly, isTrue);
    });

    test('copies showPremiumOnly', () {
      expect(base.copyWith(showPremiumOnly: true).showPremiumOnly, isTrue);
    });

    test('copies excludeBots', () {
      expect(base.copyWith(excludeBots: true).excludeBots, isTrue);
    });

    test('copies deviceType', () {
      expect(base.copyWith(deviceType: 'smart_tv').deviceType, 'smart_tv');
    });

    test('copies notificationPreference', () {
      expect(
          base.copyWith(notificationPreference: 'sms').notificationPreference,
          'sms');
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(excludeBots: true);
      expect(updated.showVerifiedOnly, base.showVerifiedOnly);
      expect(updated.showPremiumOnly, base.showPremiumOnly);
      expect(updated.deviceType, base.deviceType);
    });
  });
}
