/// Phase 3 widget tests — leaderboard screen components.
///
/// Tests key standalone widgets from the leaderboard screen without
/// requiring the full app stack or ServiceManager.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/screens/leaderboard/widgets/animated_bank_badge.dart';
import 'package:synaptix/screens/leaderboard/widgets/live_countdown_timer_widget.dart';
import 'package:synaptix/screens/question/widgets/score_display.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _riverpodWrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

// ---------------------------------------------------------------------------
// AnimatedRankBadge — leaderboard rank indicator
// ---------------------------------------------------------------------------

void main() {
  group('AnimatedRankBadge — leaderboard rank indicator', () {
    testWidgets('renders rank number as text', (tester) async {
      await tester.pumpWidget(_wrap(const AnimatedRankBadge(rank: 42)));
      expect(find.text('#42'), findsOneWidget);
    });

    testWidgets('renders rank 1 without crash', (tester) async {
      await tester.pumpWidget(_wrap(const AnimatedRankBadge(rank: 1)));
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('improvement: rank improved from 10 to 5', (tester) async {
      await tester.pumpWidget(
          _wrap(const AnimatedRankBadge(rank: 5, previousRank: 10)));
      await tester.pump();
      expect(find.text('#5'), findsOneWidget);
    });

    testWidgets('decline: rank dropped from 5 to 15', (tester) async {
      await tester.pumpWidget(
          _wrap(const AnimatedRankBadge(rank: 15, previousRank: 5)));
      await tester.pump();
      expect(find.text('#15'), findsOneWidget);
    });

    testWidgets('no previous rank (first appearance)', (tester) async {
      await tester.pumpWidget(
          _wrap(const AnimatedRankBadge(rank: 7, previousRank: null)));
      expect(find.text('#7'), findsOneWidget);
    });

    testWidgets('rank updates when widget changes', (tester) async {
      await tester.pumpWidget(_wrap(const AnimatedRankBadge(rank: 3)));
      expect(find.text('#3'), findsOneWidget);

      await tester
          .pumpWidget(_wrap(const AnimatedRankBadge(rank: 1, previousRank: 3)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('shows up arrow when rank improved', (tester) async {
      await tester.pumpWidget(
          _wrap(const AnimatedRankBadge(rank: 3, previousRank: 10)));
      await tester.pump();
      expect(
        find.byWidgetPredicate((w) =>
            w is Icon &&
            w.icon == Icons.arrow_upward &&
            w.color == Colors.green),
        findsOneWidget,
      );
    });

    testWidgets('shows down arrow when rank declined', (tester) async {
      await tester.pumpWidget(
          _wrap(const AnimatedRankBadge(rank: 15, previousRank: 3)));
      await tester.pump();
      expect(
        find.byWidgetPredicate((w) =>
            w is Icon &&
            w.icon == Icons.arrow_downward &&
            w.color == Colors.red),
        findsOneWidget,
      );
    });

    testWidgets('no arrow icon when previousRank is null', (tester) async {
      await tester.pumpWidget(_wrap(const AnimatedRankBadge(rank: 5)));
      await tester.pump();
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('no arrow icon when rank is unchanged', (tester) async {
      await tester
          .pumpWidget(_wrap(const AnimatedRankBadge(rank: 5, previousRank: 5)));
      await tester.pump();
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('animation completes without error after pumpAndSettle',
        (tester) async {
      await tester
          .pumpWidget(_wrap(const AnimatedRankBadge(rank: 2, previousRank: 8)));
      await tester.pumpAndSettle();
      expect(find.text('#2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // LiveCountdownTimer — season countdown (leaderboard screen)
  // -------------------------------------------------------------------------

  group('LiveCountdownTimer — season countdown', () {
    testWidgets('renders MM:SS format for sub-hour duration', (tester) async {
      final endTime =
          DateTime.now().add(const Duration(minutes: 5, seconds: 30));
      await tester.pumpWidget(_wrap(LiveCountdownTimer(endTime: endTime)));
      await tester.pump();

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(texts.any((t) => RegExp(r'\d{2}:\d{2}').hasMatch(t)), isTrue,
          reason: 'Expected MM:SS formatted countdown; got: $texts');
    });

    testWidgets('shows "Season ended" when time has already passed',
        (tester) async {
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));
      await tester.pumpWidget(_wrap(LiveCountdownTimer(endTime: pastTime)));
      await tester.pump();

      expect(find.textContaining('Season ended'), findsOneWidget);
    });

    testWidgets('calls onTimeExpired callback immediately when past',
        (tester) async {
      bool expired = false;
      final pastTime =
          DateTime.now().subtract(const Duration(milliseconds: 100));

      await tester.pumpWidget(_wrap(LiveCountdownTimer(
        endTime: pastTime,
        onTimeExpired: () => expired = true,
      )));
      await tester.pump();

      expect(expired, isTrue);
    });

    testWidgets('renders hours+minutes format for multi-hour duration',
        (tester) async {
      final endTime = DateTime.now().add(const Duration(hours: 3, minutes: 45));
      await tester.pumpWidget(_wrap(LiveCountdownTimer(endTime: endTime)));
      await tester.pump();

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(texts.any((t) => t.contains('h')), isTrue,
          reason: 'Expected "Xh YYm" formatted duration; got: $texts');
    });

    testWidgets('renders days+hours format for multi-day duration',
        (tester) async {
      final endTime = DateTime.now().add(const Duration(days: 2, hours: 6));
      await tester.pumpWidget(_wrap(LiveCountdownTimer(endTime: endTime)));
      await tester.pump();

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(texts.any((t) => t.contains('d')), isTrue,
          reason: 'Expected "Xd YYh" format; got: $texts');
    });
  });

  // -------------------------------------------------------------------------
  // EnhancedScoreDisplay — game screen / score summary
  // -------------------------------------------------------------------------

  group('EnhancedScoreDisplay — game score summary', () {
    testWidgets('renders without crashing with minimal params', (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 7,
        totalQuestions: 10,
      )));
      await tester.pump();
      // Widget renders; score animation starts at 0 so final value may not be
      // visible immediately — just verify no exception.
      expect(find.byType(EnhancedScoreDisplay), findsOneWidget);
    });

    testWidgets('renders with full params including XP and category scores',
        (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 8,
        totalQuestions: 10,
        totalXP: 250,
        classLevel: '6',
        categoryScores: {'science': 5, 'history': 3},
      )));
      await tester.pump();
      expect(find.byType(EnhancedScoreDisplay), findsOneWidget);
    });

    testWidgets('renders with power-up timer active', (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 10,
        totalQuestions: 10,
        totalXP: 500,
        powerUpTimeRemaining: Duration(minutes: 3),
      )));
      await tester.pump();
      expect(find.byType(EnhancedScoreDisplay), findsOneWidget);
    });

    testWidgets('perfect score (all correct) renders without crash',
        (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 10,
        totalQuestions: 10,
        totalXP: 1000,
      )));
      await tester.pump();
      expect(find.byType(EnhancedScoreDisplay), findsOneWidget);
    });

    testWidgets('zero score renders without crash', (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 0,
        totalQuestions: 10,
      )));
      await tester.pump();
      expect(find.byType(EnhancedScoreDisplay), findsOneWidget);
    });

    testWidgets('shows Your Score label and totalQuestions denominator',
        (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 7,
        totalQuestions: 10,
      )));
      await tester.pump();
      expect(find.text('Your Score'), findsOneWidget);
      expect(find.textContaining('/ 10'), findsOneWidget);
    });

    testWidgets('shows correct percentage text for 7/10', (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 7,
        totalQuestions: 10,
      )));
      await tester.pump();
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('performance message Outstanding work for >=90%',
        (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 9,
        totalQuestions: 10,
      )));
      await tester.pump();
      expect(find.text('Outstanding work!'), findsOneWidget);
    });

    testWidgets('performance message Great job for >=80%', (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 8,
        totalQuestions: 10,
      )));
      await tester.pump();
      expect(find.text('Great job!'), findsOneWidget);
    });

    testWidgets('performance message Good effort for >=70%', (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 7,
        totalQuestions: 10,
      )));
      await tester.pump();
      expect(find.text('Good effort!'), findsOneWidget);
    });

    testWidgets('performance message Keep trying for >=60%', (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 6,
        totalQuestions: 10,
      )));
      await tester.pump();
      expect(find.text('Keep trying!'), findsOneWidget);
    });

    testWidgets('performance message Practice makes perfect for <60%',
        (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 5,
        totalQuestions: 10,
      )));
      await tester.pump();
      expect(find.text('Practice makes perfect!'), findsOneWidget);
    });

    testWidgets('XP section visible when totalXP > 0', (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 8,
        totalQuestions: 10,
        totalXP: 300,
      )));
      await tester.pump();
      expect(find.text('Experience Points'), findsOneWidget);
    });

    testWidgets('XP section absent when totalXP is 0', (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 5,
        totalQuestions: 10,
        totalXP: 0,
      )));
      await tester.pump();
      expect(find.text('Experience Points'), findsNothing);
    });

    testWidgets('XP animates to final value after pumpAndSettle',
        (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 10,
        totalQuestions: 10,
        totalXP: 500,
      )));
      await tester.pumpAndSettle();
      expect(find.text('500 XP'), findsOneWidget);
    });

    testWidgets('category breakdown visible with categoryScores',
        (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 8,
        totalQuestions: 10,
        categoryScores: {'science': 5, 'history': 3},
      )));
      await tester.pump();
      expect(find.text('Subject Performance'), findsOneWidget);
      expect(find.text('SCIENCE'), findsOneWidget);
      expect(find.text('HISTORY'), findsOneWidget);
    });

    testWidgets('category breakdown absent with empty categoryScores',
        (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 5,
        totalQuestions: 10,
        categoryScores: {},
      )));
      await tester.pump();
      expect(find.text('Subject Performance'), findsNothing);
    });

    testWidgets('power-up section visible with powerUpTimeRemaining',
        (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 7,
        totalQuestions: 10,
        powerUpTimeRemaining: Duration(seconds: 45),
      )));
      await tester.pump();
      expect(find.text('Power-Up Active'), findsOneWidget);
      expect(find.text('45s'), findsOneWidget);
    });

    testWidgets('power-up section absent when powerUpTimeRemaining is null',
        (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 7,
        totalQuestions: 10,
      )));
      await tester.pump();
      expect(find.text('Power-Up Active'), findsNothing);
    });

    testWidgets('class level badge shows correct label', (tester) async {
      await tester.pumpWidget(_riverpodWrap(const EnhancedScoreDisplay(
        score: 5,
        totalQuestions: 10,
        classLevel: '6',
      )));
      await tester.pump();
      expect(find.text('Class 6'), findsOneWidget);
    });
  });
}
