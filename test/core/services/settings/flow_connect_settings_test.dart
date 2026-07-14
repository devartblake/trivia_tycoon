import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/settings/flow_connect_settings.dart';
import 'package:synaptix/game/services/flow_connect_level_generator.dart';

void main() {
  group('FlowConnectSettings', () {
    late FlowConnectSettings settings;

    setUp(() {
      settings = FlowConnectSettings();
    });

    // -------------------------------------------------------------------------
    // Initial state
    // -------------------------------------------------------------------------

    test('default gridSize is 5', () {
      expect(settings.gridSize, 5);
    });

    test('default difficulty is medium', () {
      expect(settings.difficulty, FlowConnectDifficulty.medium);
    });

    // -------------------------------------------------------------------------
    // setGridSize
    // -------------------------------------------------------------------------

    test('setGridSize updates gridSize', () {
      settings.setGridSize(7);
      expect(settings.gridSize, 7);
    });

    test('setGridSize notifies listeners when value changes', () {
      var notified = false;
      settings.addListener(() => notified = true);
      settings.setGridSize(8);
      expect(notified, isTrue);
    });

    test('setGridSize does NOT notify listeners when value is unchanged', () {
      var notifyCount = 0;
      settings.addListener(() => notifyCount++);
      settings.setGridSize(settings.gridSize); // same value
      expect(notifyCount, 0);
    });

    test('setGridSize with different values notifies each time', () {
      var notifyCount = 0;
      settings.addListener(() => notifyCount++);
      settings.setGridSize(6);
      settings.setGridSize(7);
      expect(notifyCount, 2);
    });

    // -------------------------------------------------------------------------
    // setDifficulty
    // -------------------------------------------------------------------------

    test('setDifficulty updates difficulty', () {
      settings.setDifficulty(FlowConnectDifficulty.hard);
      expect(settings.difficulty, FlowConnectDifficulty.hard);
    });

    test('setDifficulty notifies listeners when value changes', () {
      var notified = false;
      settings.addListener(() => notified = true);
      settings.setDifficulty(FlowConnectDifficulty.easy);
      expect(notified, isTrue);
    });

    test('setDifficulty does NOT notify listeners when value is unchanged', () {
      var notifyCount = 0;
      settings.addListener(() => notifyCount++);
      settings.setDifficulty(settings.difficulty); // same value
      expect(notifyCount, 0);
    });

    test('can cycle through all difficulty values', () {
      for (final diff in FlowConnectDifficulty.values) {
        settings.setDifficulty(diff);
        expect(settings.difficulty, diff);
      }
    });

    // -------------------------------------------------------------------------
    // Combined state
    // -------------------------------------------------------------------------

    test('gridSize and difficulty are independent', () {
      settings.setGridSize(9);
      settings.setDifficulty(FlowConnectDifficulty.easy);
      expect(settings.gridSize, 9);
      expect(settings.difficulty, FlowConnectDifficulty.easy);
    });
  });
}
