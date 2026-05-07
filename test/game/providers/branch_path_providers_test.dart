import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/providers/branch_path_providers.dart';

void main() {
  group('resolveInitialAutoPathStep', () {
    test('uses query step when query param is present', () {
      final step = resolveInitialAutoPathStep(
        pathIds: const ['a', 'b', 'c'],
        hasStepQueryParam: true,
        queryStep: 2,
        savedNodeId: 'a',
        fallbackStep: 0,
      );

      expect(step, 2);
    });

    test('uses saved node when query step is absent', () {
      final step = resolveInitialAutoPathStep(
        pathIds: const ['a', 'b', 'c'],
        hasStepQueryParam: false,
        savedNodeId: 'b',
        fallbackStep: 0,
      );

      expect(step, 1);
    });

    test('falls back safely to provided fallback step when saved node is missing', () {
      final step = resolveInitialAutoPathStep(
        pathIds: const ['a', 'b', 'c'],
        hasStepQueryParam: false,
        savedNodeId: 'deleted_node',
        fallbackStep: 2,
      );

      expect(step, 2);
    });
  });
}
