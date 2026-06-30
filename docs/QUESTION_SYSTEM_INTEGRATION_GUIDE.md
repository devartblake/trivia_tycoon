# Question System Integration Guide

## Overview
This guide shows how to integrate the new question system components into existing screens and services.

## Step 1: Basic Question Rendering

### Old Way (String-based type checking)
```dart
AdaptedQuestionWidget.create(
  question: currentQuestion,
  onAnswerSelected: _handleAnswer,
  showFeedback: quizState.showFeedback,
  selectedAnswer: quizState.selectedAnswer,
)
```

### New Way (Type-safe enum dispatch)
```dart
import 'widgets/question_renderer.dart';

QuestionRenderer(
  question: currentQuestion,
  onAnswerSelected: _handleAnswer,
  showFeedback: quizState.showFeedback,
  selectedAnswer: quizState.selectedAnswer,
)
```

**Benefits:**
- ✅ No string-based type checking
- ✅ Automatic dispatch to correct view based on QuestionType enum
- ✅ Supports 11 question types (multipleChoice, trueFalse, image, video, audio, etc.)

---

## Step 2: Display Question Metadata

### Old Way (Multiple chips with QuizHelpers)
```dart
Row(
  children: [
    QuizHelpers.buildMetadataChip(
      QuizHelpers.getDisplayTypeName(currentQuestion),
      QuizHelpers.getDisplayTypeColor(currentQuestion),
      QuizHelpers.getMediaTypeIcon(currentQuestion),
    ),
    QuizHelpers.buildMetadataChip(
      _getCategoryDisplayName().toUpperCase(),
      _getCategoryColor(),
      _getCategoryIcon(),
    ),
    QuizHelpers.buildMetadataChip(
      QuizHelpers.getDifficultyText(currentQuestion.difficulty).toUpperCase(),
      QuizHelpers.getDifficultyColor(currentQuestion.difficulty),
      QuizHelpers.getDifficultyIcon(currentQuestion.difficulty),
    ),
  ],
)
```

### New Way (Unified metadata component)
```dart
import 'widgets/question_metadata.dart';

QuestionMetadata(
  question: currentQuestion,
  showDifficultyBadge: true,
  showTags: true,
)
```

**Benefits:**
- ✅ Single component for all metadata
- ✅ Type-safe difficulty enum with color coding
- ✅ Automatic tag display (up to 3)
- ✅ Proper accessibility labels

---

## Step 3: Process Question Results with Progression

### Setup Services
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/question_result_provider.dart';
import '../services/question_result_service.dart';
import '../models/question_result_model.dart';

// In your Riverpod Consumer widget:
void _handleAnswerResult() {
  final resultService = ref.watch(questionResultServiceProvider);
  final currentQuestion = ref.watch(currentQuestionProvider);
  
  // Create a QuestionResult
  final result = QuestionResult(
    questionId: currentQuestion.id,
    category: currentQuestion.category,
    difficulty: currentQuestion.difficulty,
    selectedAnswer: userAnswer,
    isCorrect: isCorrect,
    timeTaken: Duration(seconds: secondsElapsed),
    baseXPReward: 100,
    baseCoinReward: 50,
  );
  
  // Process and get progression data
  final progression = await resultService.processResult(result);
  
  print('XP Earned: ${progression.xpEarned}');
  print('Coins Earned: ${progression.coinsEarned}');
  print('Streak: ${progression.streakCount}');
  print('Milestone: ${progression.milestone}');
}
```

---

## Step 4: Display Answer Feedback

### Old Way (Custom dialog with 250+ lines)
```dart
await _showEnhancedFeedbackDialog(
  isCorrect: isCorrect,
  question: currentQuestion,
  correctAnswer: evaluation.correctAnswer,
  xpGained: xpGained,
  hasTimeBonus: hasTimeBonus,
  isTimeout: isTimeout,
  onNext: onNext,
);
```

### New Way (Modular feedback component)
```dart
import 'widgets/question_feedback_panel.dart';

showDialog(
  context: context,
  builder: (context) => Dialog(
    child: QuestionFeedbackPanel(
      isCorrect: isCorrect,
      explanation: currentQuestion.powerUpHint,
      hint: 'Try thinking about...',
      onNext: onNext,
      xpEarned: progression.xpEarned,
      coinsEarned: progression.coinsEarned,
      streakBonus: progression.streakBonusApplied,
    ),
  ),
);
```

**Benefits:**
- ✅ Reusable component (not tied to dialog)
- ✅ Clean separation of concerns
- ✅ Easy to test
- ✅ Can be used in different contexts (modal, inline, bottom sheet)

---

## Step 5: Add Timer to Question Screen

### Setup
```dart
import 'widgets/question_timer.dart';

// In build method
Stack(
  children: [
    // Your question content
    QuestionContent(...),
    
    // Timer in corner
    Positioned(
      top: 16,
      right: 16,
      child: QuestionTimer(
        duration: 30, // seconds
        onTimeUp: _handleTimeout,
        isPaused: false,
      ),
    ),
  ],
)
```

**Features:**
- ✅ Progressive color coding: green → orange → red
- ✅ Pulse animation when ≤10 seconds
- ✅ Pause state indicator
- ✅ Smooth progress ring

---

## Step 6: Progression Multipliers

The system automatically applies multipliers based on difficulty:

### XP Multipliers
- Easy: 1.0x
- Medium: 1.5x
- Hard: 2.0x
- Expert: 3.0x
- Boss: 5.0x

### Coin Multipliers
- Easy: 1.0x
- Medium: 1.25x
- Hard: 1.5x
- Expert: 2.0x
- Boss: 3.0x

### Time Bonuses
- ≤50% of time limit: +50% bonus
- ≤100% of time limit: Normal reward
- >Time limit: 50% penalty

### Streak Bonuses
- 1-4 correct: No bonus
- 5+ correct: 1.1x to 2.0x multiplier (difficulty-dependent)
- Timeout: 30 minutes between correct answers to maintain streak

---

## Step 7: Milestones and Achievements

QuestionResultService automatically detects:

### XP Milestones
- 10,000 XP
- 50,000 XP
- 100,000 XP

### Streak Milestones
- 5 Question Streak
- 10 Question Streak 🔥
- 25 Question Streak 🌟

Access via:
```dart
final progression = await resultService.processResult(result);
if (progression.milestone != null) {
  showMilestoneNotification(progression.milestone!);
}
```

---

## Migration Checklist

- [ ] Update imports to use new components
- [ ] Replace AdaptedQuestionWidget with QuestionRenderer
- [ ] Replace metadata chips with QuestionMetadata
- [ ] Integrate QuestionResultService for progression
- [ ] Update feedback dialog to use QuestionFeedbackPanel
- [ ] Add QuestionTimer to screen
- [ ] Test difficulty multipliers
- [ ] Test streak tracking
- [ ] Test milestone detection
- [ ] Verify analytics capture with QuestionResultModel

---

## Common Patterns

### Pattern 1: Complete Question Flow
```dart
// 1. Display question
QuestionRenderer(question: q, onAnswerSelected: _handleAnswer)

// 2. Show timer
QuestionTimer(duration: 30, onTimeUp: _handleTimeout)

// 3. Process result
final progression = await resultService.processResult(result);

// 4. Show feedback
QuestionFeedbackPanel(
  isCorrect: progression.xpEarned > 0,
  xpEarned: progression.xpEarned,
  coinsEarned: progression.coinsEarned,
  streakBonus: progression.streakBonusApplied,
  onNext: nextQuestion,
)

// 5. Display metadata
QuestionMetadata(question: q)
```

### Pattern 2: Analytics Tracking
```dart
// Persist result for analytics
final resultModel = QuestionResultModel(
  questionId: result.questionId,
  category: result.category,
  difficulty: result.difficulty,
  isCorrect: result.isCorrect,
  timeTakenSeconds: result.timeTaken.inSeconds,
  xpEarned: progression.xpEarned,
  coinsEarned: progression.coinsEarned,
  streakCountAtAnswer: progression.streakCount ?? 0,
);

// Save to database/analytics
await analyticsService.saveQuestionResult(resultModel);
```

### Pattern 3: Arcade/Mini-Game Integration
```dart
// QuestionRenderer works in any context
final renderedQuestion = QuestionRenderer(
  question: arcadeQuestion,
  onAnswerSelected: (answer) {
    // Handle arcade-specific logic
    arcade.recordAnswer(answer);
  },
);
```

---

## Type Safety Guarantees

The new system eliminates runtime errors from string-based types:

```dart
// ❌ Old way - runtime error if type is misspelled
if (question.type == "multiple_choise") { } // Oops!

// ✅ New way - compile-time error
if (question.type == QuestionType.multipleChoice) { } // Catches typos!
```

---

## Performance Considerations

- **Memory**: Components are lightweight, no unnecessary rebuilds
- **Rendering**: QuestionRenderer uses enum switch (O(1) dispatch)
- **Services**: XPService and WalletService use in-memory caching with Hive persistence
- **Animations**: Timer uses AnimationController with proper cleanup

---

## Testing

```dart
// Test progression calculation
test('Hard difficulty applies 2x XP multiplier', () {
  final result = QuestionResult(
    difficulty: QuestionDifficulty.hard,
    isCorrect: true,
    timeTaken: Duration(seconds: 15),
    baseXPReward: 100,
    // ...
  );
  
  final progression = resultService.processResult(result);
  expect(progression.xpEarned, equals(200)); // 100 * 2.0
});

// Test streak timeout
test('Streak resets after 30 minutes of inactivity', () {
  resultService.processResult(correctResult);
  expect(resultService.streak, equals(1));
  
  // Advance time 31 minutes
  clock.jump(Duration(minutes: 31));
  
  resultService.processResult(correctResult);
  expect(resultService.streak, equals(1)); // Reset
});
```

---

## Troubleshooting

**Q: Timer not appearing**  
A: Ensure QuestionTimer is in a Stack with proper positioning.

**Q: Progression not saving**  
A: Verify XPService and WalletService are properly initialized and have storage.

**Q: Difficulty multipliers not applying**  
A: Check that question.difficulty is QuestionDifficulty enum, not string.

**Q: Streak not tracking**  
A: Streak timeout is 30 minutes. Call processResult() within that window.

---

## Next Steps

1. Migrate question_view_screen.dart to use new components
2. Refactor feedback dialog to use QuestionFeedbackPanel
3. Add analytics integration with QuestionResultModel
4. Implement skill tree/achievement system using milestone data
5. Add widget tests for each component
