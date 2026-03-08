import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/settings/onboarding_settings_service.dart';

void main() {
  group('OnboardingProgress model', () {
    test('toMap/fromMap round-trips all supported fields', () {
      final source = OnboardingProgress(
        completed: true,
        hasSeenIntro: true,
        hasCompletedProfile: true,
        currentStep: 5,
        username: 'TriviaPro',
        ageGroup: '18_24',
        country: 'United States',
        categories: const ['science', 'history'],
        lastUpdatedAt: DateTime.parse('2024-01-01T12:34:56.000Z'),
      );

      final mapped = source.toMap();
      final reconstructed = OnboardingProgress.fromMap(mapped);

      expect(reconstructed.completed, true);
      expect(reconstructed.hasSeenIntro, true);
      expect(reconstructed.hasCompletedProfile, true);
      expect(reconstructed.currentStep, 5);
      expect(reconstructed.username, 'TriviaPro');
      expect(reconstructed.ageGroup, '18_24');
      expect(reconstructed.country, 'United States');
      expect(reconstructed.categories, ['science', 'history']);
      expect(
        reconstructed.lastUpdatedAt?.toIso8601String(),
        '2024-01-01T12:34:56.000Z',
      );
    });

    test('fromMap applies defaults when keys are missing', () {
      final reconstructed = OnboardingProgress.fromMap({});

      expect(reconstructed.completed, false);
      expect(reconstructed.hasSeenIntro, false);
      expect(reconstructed.hasCompletedProfile, false);
      expect(reconstructed.currentStep, 0);
      expect(reconstructed.username, isNull);
      expect(reconstructed.ageGroup, isNull);
      expect(reconstructed.country, isNull);
      expect(reconstructed.categories, isEmpty);
      expect(reconstructed.lastUpdatedAt, isNull);
    });
  });
}
