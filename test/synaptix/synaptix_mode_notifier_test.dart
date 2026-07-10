import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode_notifier.dart';

void main() {
  // -------------------------------------------------------------------------
  // mapAgeGroupToMode — static pure method, no Hive/platform deps
  // -------------------------------------------------------------------------

  group('SynaptixModeNotifier.mapAgeGroupToMode', () {
    // --- kids variants ---
    test('"kids" → SynaptixMode.kids', () {
      expect(SynaptixModeNotifier.mapAgeGroupToMode('kids'), SynaptixMode.kids);
    });

    test('"child" → SynaptixMode.kids', () {
      expect(
          SynaptixModeNotifier.mapAgeGroupToMode('child'), SynaptixMode.kids);
    });

    test('"children" → SynaptixMode.kids', () {
      expect(SynaptixModeNotifier.mapAgeGroupToMode('children'),
          SynaptixMode.kids);
    });

    test('"elementary" → SynaptixMode.kids', () {
      expect(SynaptixModeNotifier.mapAgeGroupToMode('elementary'),
          SynaptixMode.kids);
    });

    test('"k-5" → SynaptixMode.kids', () {
      expect(SynaptixModeNotifier.mapAgeGroupToMode('k-5'), SynaptixMode.kids);
    });

    // --- teen variants ---
    test('"teen" → SynaptixMode.teen', () {
      expect(SynaptixModeNotifier.mapAgeGroupToMode('teen'), SynaptixMode.teen);
    });

    test('"teens" → SynaptixMode.teen', () {
      expect(
          SynaptixModeNotifier.mapAgeGroupToMode('teens'), SynaptixMode.teen);
    });

    test('"middle" → SynaptixMode.teen', () {
      expect(
          SynaptixModeNotifier.mapAgeGroupToMode('middle'), SynaptixMode.teen);
    });

    test('"middle school" → SynaptixMode.teen', () {
      expect(SynaptixModeNotifier.mapAgeGroupToMode('middle school'),
          SynaptixMode.teen);
    });

    // --- adult (default) ---
    test('"adult" → SynaptixMode.adult', () {
      expect(
          SynaptixModeNotifier.mapAgeGroupToMode('adult'), SynaptixMode.adult);
    });

    test('"senior" → SynaptixMode.adult (default)', () {
      expect(
          SynaptixModeNotifier.mapAgeGroupToMode('senior'), SynaptixMode.adult);
    });

    test('empty string → SynaptixMode.adult (default)', () {
      expect(SynaptixModeNotifier.mapAgeGroupToMode(''), SynaptixMode.adult);
    });

    test('unrecognized string → SynaptixMode.adult (default)', () {
      expect(SynaptixModeNotifier.mapAgeGroupToMode('unknown_group'),
          SynaptixMode.adult);
    });

    // --- case-insensitive ---
    test('"KIDS" uppercase → SynaptixMode.kids', () {
      expect(SynaptixModeNotifier.mapAgeGroupToMode('KIDS'), SynaptixMode.kids);
    });

    test('"Teen" mixed case → SynaptixMode.teen', () {
      expect(SynaptixModeNotifier.mapAgeGroupToMode('Teen'), SynaptixMode.teen);
    });

    test('"ADULT" uppercase → SynaptixMode.adult', () {
      expect(
          SynaptixModeNotifier.mapAgeGroupToMode('ADULT'), SynaptixMode.adult);
    });
  });
}
