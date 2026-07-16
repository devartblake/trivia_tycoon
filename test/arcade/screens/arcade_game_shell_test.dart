import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/arcade/domain/arcade_difficulty.dart';
import 'package:synaptix/arcade/domain/arcade_game_definition.dart';
import 'package:synaptix/arcade/domain/arcade_game_id.dart';
import 'package:synaptix/arcade/ui/screens/arcade_game_shell.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A unique widget type so we can confirm the shell mounted the correct child.
class _FakeGameScreen extends StatelessWidget {
  const _FakeGameScreen({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(label);
}

ArcadeGameDefinition _fakeGame(ArcadeGameId id, String label) {
  return ArcadeGameDefinition(
    id: id,
    title: label,
    subtitle: '',
    icon: Icons.gamepad,
    supportedDifficulties: const [ArcadeDifficulty.easy],
    builder: (_, __) => _FakeGameScreen(label: label),
  );
}

Widget _shell(ArcadeGameDefinition game) {
  return ProviderScope(
    child: MaterialApp(
      home: ArcadeGameShell(
        game: game,
        difficulty: ArcadeDifficulty.easy,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ArcadeGameShell', () {
    testWidgets('mounts patternSprint game widget', (tester) async {
      await tester.pumpWidget(
        _shell(_fakeGame(ArcadeGameId.patternSprint, 'pattern-sprint')),
      );
      await tester.pump();

      expect(find.text('pattern-sprint'), findsOneWidget);
      expect(find.byType(ArcadeGameShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mounts memoryFlip game widget', (tester) async {
      await tester.pumpWidget(
        _shell(_fakeGame(ArcadeGameId.memoryFlip, 'memory-flip')),
      );
      await tester.pump();

      expect(find.text('memory-flip'), findsOneWidget);
      expect(find.byType(ArcadeGameShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mounts quickMathRush game widget', (tester) async {
      await tester.pumpWidget(
        _shell(_fakeGame(ArcadeGameId.quickMathRush, 'quick-math-rush')),
      );
      await tester.pump();

      expect(find.text('quick-math-rush'), findsOneWidget);
      expect(find.byType(ArcadeGameShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ArcadeRunApi is accessible from game widget via .of(context)',
        (tester) async {
      ArcadeRunApi? capturedApi;

      final gameWithApiCapture = ArcadeGameDefinition(
        id: ArcadeGameId.patternSprint,
        title: 'api-capture',
        subtitle: '',
        icon: Icons.gamepad,
        supportedDifficulties: const [ArcadeDifficulty.easy],
        builder: (ctx, _) {
          capturedApi = ArcadeGameShell.of(ctx);
          return const Text('api-capture');
        },
      );

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: ArcadeGameShell(
            game: gameWithApiCapture,
            difficulty: ArcadeDifficulty.easy,
          ),
        ),
      ));
      await tester.pump();

      expect(capturedApi, isNotNull);
      expect(capturedApi!.game.id, ArcadeGameId.patternSprint);
      expect(capturedApi!.difficulty, ArcadeDifficulty.easy);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shell passes difficulty to game builder', (tester) async {
      ArcadeDifficulty? capturedDifficulty;

      final gameCapture = ArcadeGameDefinition(
        id: ArcadeGameId.quickMathRush,
        title: 'difficulty-check',
        subtitle: '',
        icon: Icons.gamepad,
        supportedDifficulties: const [ArcadeDifficulty.hard],
        builder: (_, diff) {
          capturedDifficulty = diff;
          return const Text('difficulty-check');
        },
      );

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: ArcadeGameShell(
            game: gameCapture,
            difficulty: ArcadeDifficulty.hard,
          ),
        ),
      ));
      await tester.pump();

      expect(capturedDifficulty, ArcadeDifficulty.hard);
    });
  });
}
