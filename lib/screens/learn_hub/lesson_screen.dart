import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dto/learning_dto.dart';
import '../../game/providers/learning_providers.dart';

class LessonScreen extends ConsumerWidget {
  final String moduleId;

  const LessonScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider(moduleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Could not load lessons.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.refresh(lessonsProvider(moduleId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (lessons) => lessons.isEmpty
            ? const Center(child: Text('No lessons available.'))
            : _LessonFlow(moduleId: moduleId, lessons: lessons),
      ),
    );
  }
}

class _LessonFlow extends ConsumerStatefulWidget {
  final String moduleId;
  final List<LessonDto> lessons;

  const _LessonFlow({required this.moduleId, required this.lessons});

  @override
  ConsumerState<_LessonFlow> createState() => _LessonFlowState();
}

class _LessonFlowState extends ConsumerState<_LessonFlow> {
  bool _completing = false;

  @override
  Widget build(BuildContext context) {
    final flowState =
        ref.watch(lessonFlowProvider(widget.lessons));
    final notifier =
        ref.read(lessonFlowProvider(widget.lessons).notifier);
    final lesson = widget.lessons[flowState.currentIndex];
    final total = widget.lessons.length;
    final current = flowState.currentIndex + 1;

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: current / total,
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $current of $total',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                lesson.questionCategory,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Text(
                  lesson.questionText,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Option buttons
                ...lesson.options.map((option) {
                  return _OptionTile(
                    option: option,
                    selectedOptionId: flowState.selectedOptionId,
                    correctOptionId: lesson.correctOptionId,
                    answered: flowState.answered,
                    onTap: flowState.answered
                        ? null
                        : () => notifier.selectOption(option.id),
                  );
                }),

                // Explanation (shown after answering)
                if (flowState.answered && lesson.explanation != null) ...[
                  const SizedBox(height: 16),
                  _ExplanationBox(text: lesson.explanation!),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Bottom action button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: flowState.answered
                  ? _completing
                      ? const FilledButton(
                          onPressed: null,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      : FilledButton(
                          onPressed: () => _onNext(notifier, flowState),
                          child: Text(
                            notifier.isLastLesson ? 'Finish' : 'Next',
                          ),
                        )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onNext(
      LessonFlowNotifier notifier, LessonFlowState flowState) async {
    if (notifier.isLastLesson) {
      await _completeModule();
    } else {
      notifier.nextLesson();
    }
  }

  Future<void> _completeModule() async {
    if (_completing) return;
    setState(() => _completing = true);

    try {
      final playerIdAsync =
          await ref.read(currentPlayerIdProvider.future);
      final playerId = playerIdAsync ?? '';

      final result = await ref
          .read(learningRepositoryProvider)
          .completeModule(widget.moduleId, playerId);

      if (mounted) {
        context.pushReplacement(
          '/learn-hub/module/${widget.moduleId}/complete',
          extra: result,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _completing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save completion. Please try again.'),
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Option tile
// ---------------------------------------------------------------------------

class _OptionTile extends StatelessWidget {
  final LessonOptionDto option;
  final String? selectedOptionId;
  final String correctOptionId;
  final bool answered;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.option,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color borderColor = Colors.grey.shade300;
    Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    if (answered) {
      if (option.id == correctOptionId) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade800;
      } else if (option.id == selectedOptionId) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade800;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            _OptionBadge(id: option.id, textColor: textColor, borderColor: borderColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.text,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: textColor, fontWeight: FontWeight.w500),
              ),
            ),
            if (answered && option.id == correctOptionId)
              Icon(Icons.check_circle, color: Colors.green, size: 20),
            if (answered &&
                option.id == selectedOptionId &&
                option.id != correctOptionId)
              Icon(Icons.cancel, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }
}

class _OptionBadge extends StatelessWidget {
  final String id;
  final Color textColor;
  final Color borderColor;

  const _OptionBadge({
    required this.id,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        id,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: textColor,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Explanation box
// ---------------------------------------------------------------------------

class _ExplanationBox extends StatelessWidget {
  final String text;

  const _ExplanationBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade900,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
