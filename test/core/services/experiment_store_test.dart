import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/dto/personalization_dto.dart';
import 'package:trivia_tycoon/core/services/personalization/experiment_store.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ExperimentAssignmentDto _assignment({
  String experimentKey = 'exp_key',
  String variantKey = 'variant_a',
  bool isControl = false,
  Map<String, dynamic> config = const {},
}) =>
    ExperimentAssignmentDto(
      experimentKey: experimentKey,
      variantKey: variantKey,
      isControl: isControl,
      config: config,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Reset the singleton before each test so state doesn't leak between tests.
  setUp(() => ExperimentStore.instance.clear());
  tearDown(() => ExperimentStore.instance.clear());

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('ExperimentStore — initial state', () {
    test('isSeeded is false before seed() is called', () {
      expect(ExperimentStore.instance.isSeeded, isFalse);
    });

    test('get returns null for any key before seeding', () {
      expect(ExperimentStore.instance.get('any_key'), isNull);
    });

    test('isInVariant returns false for any key before seeding', () {
      expect(ExperimentStore.instance.isInVariant('any_key'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // seed
  // -------------------------------------------------------------------------

  group('ExperimentStore.seed', () {
    test('sets isSeeded to true', () {
      ExperimentStore.instance.seed([]);
      expect(ExperimentStore.instance.isSeeded, isTrue);
    });

    test('get returns the correct assignment after seeding', () {
      final a = _assignment(experimentKey: 'color_test', variantKey: 'blue');
      ExperimentStore.instance.seed([a]);
      final result = ExperimentStore.instance.get('color_test');
      expect(result?.variantKey, 'blue');
    });

    test('multiple assignments are all stored', () {
      ExperimentStore.instance.seed([
        _assignment(experimentKey: 'a'),
        _assignment(experimentKey: 'b'),
        _assignment(experimentKey: 'c'),
      ]);
      expect(ExperimentStore.instance.get('a'), isNotNull);
      expect(ExperimentStore.instance.get('b'), isNotNull);
      expect(ExperimentStore.instance.get('c'), isNotNull);
    });

    test('second seed call overwrites all previous assignments', () {
      ExperimentStore.instance.seed([_assignment(experimentKey: 'old')]);
      ExperimentStore.instance.seed([_assignment(experimentKey: 'new')]);
      expect(ExperimentStore.instance.get('old'), isNull);
      expect(ExperimentStore.instance.get('new'), isNotNull);
    });

    test('seeding with empty list clears previous assignments', () {
      ExperimentStore.instance.seed([_assignment(experimentKey: 'gone')]);
      ExperimentStore.instance.seed([]);
      expect(ExperimentStore.instance.get('gone'), isNull);
    });

    test('isSeeded remains true after re-seeding with empty list', () {
      ExperimentStore.instance.seed([]);
      expect(ExperimentStore.instance.isSeeded, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // get
  // -------------------------------------------------------------------------

  group('ExperimentStore.get', () {
    test('returns null for unknown key after seeding', () {
      ExperimentStore.instance.seed([_assignment(experimentKey: 'known')]);
      expect(ExperimentStore.instance.get('unknown'), isNull);
    });

    test('returned assignment preserves all fields', () {
      final a = _assignment(
        experimentKey: 'btn_test',
        variantKey: 'green',
        isControl: false,
        config: {'size': 'large'},
      );
      ExperimentStore.instance.seed([a]);
      final result = ExperimentStore.instance.get('btn_test')!;
      expect(result.experimentKey, 'btn_test');
      expect(result.variantKey, 'green');
      expect(result.isControl, isFalse);
      expect(result.config['size'], 'large');
    });
  });

  // -------------------------------------------------------------------------
  // isInVariant
  // -------------------------------------------------------------------------

  group('ExperimentStore.isInVariant', () {
    test('returns false for control assignment', () {
      ExperimentStore.instance.seed([
        _assignment(experimentKey: 'ctrl', isControl: true),
      ]);
      expect(ExperimentStore.instance.isInVariant('ctrl'), isFalse);
    });

    test('returns true for non-control assignment', () {
      ExperimentStore.instance.seed([
        _assignment(experimentKey: 'treat', isControl: false),
      ]);
      expect(ExperimentStore.instance.isInVariant('treat'), isTrue);
    });

    test('returns false for unknown key even after seeding', () {
      ExperimentStore.instance.seed([_assignment(experimentKey: 'known')]);
      expect(ExperimentStore.instance.isInVariant('not_enrolled'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // clear
  // -------------------------------------------------------------------------

  group('ExperimentStore.clear', () {
    test('resets isSeeded to false', () {
      ExperimentStore.instance.seed([_assignment()]);
      ExperimentStore.instance.clear();
      expect(ExperimentStore.instance.isSeeded, isFalse);
    });

    test('get returns null for all previously stored keys after clear', () {
      ExperimentStore.instance.seed([
        _assignment(experimentKey: 'x'),
        _assignment(experimentKey: 'y'),
      ]);
      ExperimentStore.instance.clear();
      expect(ExperimentStore.instance.get('x'), isNull);
      expect(ExperimentStore.instance.get('y'), isNull);
    });
  });
}
