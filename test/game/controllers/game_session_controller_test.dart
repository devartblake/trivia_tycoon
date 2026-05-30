import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:trivia_tycoon/game/controllers/game_session_controller.dart';
import 'package:trivia_tycoon/game/logic/skill_effect_handler.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';
import 'package:trivia_tycoon/game/services/game_session.dart';

// ---------------------------------------------------------------------------
// Manual Mockito mocks (no code generation required)
// ---------------------------------------------------------------------------

// ignore: must_be_immutable
class MockSkillEffectHandler extends Mock implements SkillEffectHandler {}

// ignore: must_be_immutable
class MockGameSession extends Mock implements GameSession {}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

SkillNode _node({
  String id = 'skill_1',
  Map<String, num> effects = const {'xpBoost': 1.5},
  bool available = true,
  bool unlocked = true,
}) =>
    SkillNode(
      id: id,
      title: 'Test Skill',
      description: 'A skill used in tests',
      tier: 1,
      cost: 10,
      category: SkillCategory.scholar,
      effects: effects,
      available: available,
      unlocked: unlocked,
    );

ProviderContainer _container(
  MockSkillEffectHandler handler,
  MockGameSession session,
) =>
    ProviderContainer(
      overrides: [
        gameSessionProvider.overrideWithValue(session),
        skillEffectHandlerProvider.overrideWithValue(handler),
      ],
    );

void main() {
  // -------------------------------------------------------------------------
  // useSkill — delegates entirely to effectHandler.triggerSkill
  // -------------------------------------------------------------------------

  group('useSkill return value', () {
    test('returns true when effectHandler.triggerSkill returns true', () {
      final handler = MockSkillEffectHandler();
      final session = MockGameSession();
      when(handler.triggerSkill(any)).thenReturn(true);

      final container = _container(handler, session);
      addTearDown(container.dispose);

      final ctrl = container.read(gameSessionControllerProvider.notifier);
      expect(ctrl.useSkill(_node()), isTrue);
    });

    test('returns false when effectHandler.triggerSkill returns false', () {
      final handler = MockSkillEffectHandler();
      final session = MockGameSession();
      when(handler.triggerSkill(any)).thenReturn(false);

      final container = _container(handler, session);
      addTearDown(container.dispose);

      final ctrl = container.read(gameSessionControllerProvider.notifier);
      expect(ctrl.useSkill(_node()), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // useSkill — interaction verification
  // -------------------------------------------------------------------------

  group('useSkill interaction with effectHandler', () {
    test('calls triggerSkill exactly once per useSkill call', () {
      final handler = MockSkillEffectHandler();
      final session = MockGameSession();
      when(handler.triggerSkill(any)).thenReturn(true);

      final container = _container(handler, session);
      addTearDown(container.dispose);

      final ctrl = container.read(gameSessionControllerProvider.notifier);
      final node = _node();

      ctrl.useSkill(node);

      verify(handler.triggerSkill(node)).called(1);
    });

    test('calls triggerSkill twice when useSkill is called twice', () {
      final handler = MockSkillEffectHandler();
      final session = MockGameSession();
      when(handler.triggerSkill(any)).thenReturn(true);

      final container = _container(handler, session);
      addTearDown(container.dispose);

      final ctrl = container.read(gameSessionControllerProvider.notifier);
      ctrl.useSkill(_node());
      ctrl.useSkill(_node());

      verify(handler.triggerSkill(any)).called(2);
    });

    test('passes the exact SkillNode to triggerSkill', () {
      final handler = MockSkillEffectHandler();
      final session = MockGameSession();
      SkillNode? captured;
      when(handler.triggerSkill(any)).thenAnswer((inv) {
        captured = inv.positionalArguments[0] as SkillNode;
        return true;
      });

      final container = _container(handler, session);
      addTearDown(container.dispose);

      final ctrl = container.read(gameSessionControllerProvider.notifier);
      final node = _node(id: 'specific_skill');
      ctrl.useSkill(node);

      expect(captured?.id, 'specific_skill');
    });

    test('different nodes are passed through correctly', () {
      final handler = MockSkillEffectHandler();
      final session = MockGameSession();
      final captured = <String>[];
      when(handler.triggerSkill(any)).thenAnswer((inv) {
        captured.add((inv.positionalArguments[0] as SkillNode).id);
        return true;
      });

      final container = _container(handler, session);
      addTearDown(container.dispose);

      final ctrl = container.read(gameSessionControllerProvider.notifier);
      ctrl.useSkill(_node(id: 'skill_a'));
      ctrl.useSkill(_node(id: 'skill_b'));

      expect(captured, ['skill_a', 'skill_b']);
    });
  });

  // -------------------------------------------------------------------------
  // Provider setup — state is initialised from gameSessionProvider
  // -------------------------------------------------------------------------

  group('provider state', () {
    test('controller state equals the overridden gameSessionProvider value', () {
      final handler = MockSkillEffectHandler();
      final session = MockGameSession();
      when(handler.triggerSkill(any)).thenReturn(true);

      final container = _container(handler, session);
      addTearDown(container.dispose);

      // StateNotifier<GameSession>.state should be the mocked session
      expect(container.read(gameSessionControllerProvider), same(session));
    });

    test('effectHandler is the overridden skillEffectHandlerProvider value', () {
      final handler = MockSkillEffectHandler();
      final session = MockGameSession();

      final container = _container(handler, session);
      addTearDown(container.dispose);

      final ctrl = container.read(gameSessionControllerProvider.notifier);
      expect(ctrl.effectHandler, same(handler));
    });
  });
}
