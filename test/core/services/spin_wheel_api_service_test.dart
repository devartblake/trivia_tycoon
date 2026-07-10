import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/arcade/spin_wheel_api_service.dart';

void main() {
  group('SpinStartResponse', () {
    test('fromJson with all fields parses correctly', () {
      final expiry = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 10))
          .toIso8601String();
      final response = SpinStartResponse.fromJson({
        'spinId': 'srv-spin-abc',
        'segmentId': 'seg-gold',
        'wheelStopIndex': 4,
        'claimToken': 'tok-xyz',
        'expiresAtUtc': expiry,
      });

      expect(response.spinId, 'srv-spin-abc');
      expect(response.segmentId, 'seg-gold');
      expect(response.wheelStopIndex, 4);
      expect(response.claimToken, 'tok-xyz');
      expect(response.expiresAtUtc, isNotNull);
      expect(response.expiresAtUtc.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test(
        'fromJson with missing optional fields — segmentId and wheelStopIndex are null',
        () {
      final expiry = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 5))
          .toIso8601String();
      final response = SpinStartResponse.fromJson({
        'spinId': 'srv-spin-def',
        'claimToken': 'tok-abc',
        'expiresAtUtc': expiry,
      });

      expect(response.spinId, 'srv-spin-def');
      expect(response.claimToken, 'tok-abc');
      expect(response.segmentId, isNull);
      expect(response.wheelStopIndex, isNull);
    });

    test(
        'fromJson with missing expiresAtUtc — defaults to roughly 5 minutes from now',
        () {
      final before = DateTime.now().toUtc();
      final response = SpinStartResponse.fromJson({
        'spinId': 'srv-spin-ghi',
        'claimToken': 'tok-def',
      });
      final after = DateTime.now().toUtc().add(const Duration(minutes: 6));

      expect(response.expiresAtUtc, isNotNull);
      expect(response.expiresAtUtc.isAfter(before), isTrue);
      expect(response.expiresAtUtc.isBefore(after), isTrue);
    });
  });
}
