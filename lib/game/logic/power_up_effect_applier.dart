import '../models/power_up.dart';
import '../models/question_model.dart';

class PowerUpEffectApplier {
  /// Applies power-up effects to the given question.
  static QuestionModel apply(PowerUp? powerUp, QuestionModel question) {
    if (powerUp == null || powerUp.id == 'none') return question;

    switch (powerUp.type.toLowerCase()) {
      case 'hint':
        return question.copyWith(showHint: true);
      case 'eliminate':
        return _applyEliminateOption(question);
      case 'xp':
        return question.copyWith(multiplier: 2);
      case 'boost':
        return question.copyWith(isBoostedTime: true);
      case 'shield':
        return question.copyWith(isShielded: true);
      default:
        return question;
    }
  }

  /// Removes one wrong choice from the available options.
  static QuestionModel _applyEliminateOption(QuestionModel question) {
    final incorrectChoices =
    question.options.where((c) => c != question.correctAnswer).toList();

    if (incorrectChoices.isNotEmpty) {
      incorrectChoices.shuffle();
      final filtered = question.options.where((c) =>
      c == question.correctAnswer || c == incorrectChoices.first).toList();

      return question.copyWith(
          options: filtered,          // Use reduced options in UI
          reducedOptions: filtered,   // Store the result for later logic
      );
    }
    return question;
  }
}
