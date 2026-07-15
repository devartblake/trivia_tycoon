import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/screens/onboarding/steps/age_verification_step.dart';

void main() {
  group('AgeVerificationStep.ageFromDateOfBirth', () {
    test('counts full years before birthday this year', () {
      final dob = DateTime(2010, 12, 31);
      final asOf = DateTime(2026, 6, 1);
      expect(AgeVerificationStep.ageFromDateOfBirth(dob, asOf), 15);
    });

    test('counts full years on/after birthday', () {
      final dob = DateTime(2010, 1, 1);
      final asOf = DateTime(2026, 1, 1);
      expect(AgeVerificationStep.ageFromDateOfBirth(dob, asOf), 16);
    });

    test('marks under-13 as kids age group', () {
      expect(AgeVerificationStep.ageGroupIdForAge(12), 'kids');
      expect(AgeVerificationStep.ageGroupIdForAge(13), 'teens');
      expect(AgeVerificationStep.ageGroupIdForAge(18), 'adults');
      expect(AgeVerificationStep.ageGroupIdForAge(30), 'general');
    });
  });
}
