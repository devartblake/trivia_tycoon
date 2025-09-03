import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/riverpod_providers.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  bool _showingFeedback = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  Future<void> showFeedbackDialog({
    required BuildContext context,
    required bool isCorrect,
    required VoidCallback onNext,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Feedback',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isCorrect ? "Correct!" : "Oops!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onNext();
                      },
                      child: const Text("Next Question"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAnswer(String answer) async {
    final controller = ref.read(questionControllerProvider.notifier);
    final state = ref.read(questionControllerProvider);
    final question = state.currentQuestion;

    final isCorrect = question?.isCorrectAnswer(answer) ?? false;

    setState(() => _showingFeedback = true);

    await showFeedbackDialog(
      context: context,
      isCorrect: isCorrect,
      onNext: () {
        final isLast = state.currentIndex + 1 >= state.questions.length;

        if (isLast) {
          Navigator.pushReplacementNamed(
            context,
            '/score-summary',
            arguments: {
              'score': state.score,
              'money': state.money,
              'diamonds': state.diamonds,
            },
          );
        } else {
          controller.nextQuestion();
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }

        setState(() => _showingFeedback = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionControllerProvider);

    if (state.questions.isEmpty || state.currentQuestion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = state.currentQuestion!;
    final displayOptions = question.reducedOptions ?? question.options;

    return Scaffold(
      appBar: AppBar(
        title: Text("Question ${state.currentIndex + 1}"),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.questions.length,
        itemBuilder: (context, index) {
          if (index != state.currentIndex) return const SizedBox();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                /// Hint display
                if (question.showHint && question.powerUpHint?.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text(question.powerUpHint!)),
                      ],
                    ),
                  ),

                /// Answer buttons
                ...displayOptions.map((option) {
                  final isSelected = option == state.selectedAnswer;
                  final isCorrect = question.isCorrectAnswer(option);
                  Color? color;

                  if (_showingFeedback) {
                    if (isSelected && isCorrect) {
                      color = Colors.green;
                    } else if (isSelected && !isCorrect) {
                      color = Colors.red;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                      ),
                      onPressed: _showingFeedback
                          ? null
                          : () => _handleAnswer(option),
                      child: Text(option),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
