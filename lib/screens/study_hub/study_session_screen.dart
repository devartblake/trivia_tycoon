import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dto/study_dto.dart';
import '../../core/services/study/study_service.dart';
import '../../game/providers/study_providers.dart';

class StudySessionScreen extends ConsumerStatefulWidget {
  final StudySession initialSession;

  const StudySessionScreen({super.key, required this.initialSession});

  @override
  ConsumerState<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends ConsumerState<StudySessionScreen> {
  late StudySession _session;
  StudySetDetail? _detail;
  bool _loading = false;
  bool _answerRevealed = false;
  String? _selectedOptionId;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await ref
          .read(studyServiceProvider)
          .fetchStudySet(_session.studySetId);
      if (mounted) setState(() => _detail = detail);
    } catch (_) {}
  }

  StudyQuestion? get _currentQuestion {
    if (_detail == null) return null;
    final idx = _session.currentQuestionIndex;
    if (idx >= _detail!.questions.length) return null;
    return _detail!.questions[idx];
  }

  Future<void> _submitSelfTest(String optionId) async {
    final q = _currentQuestion;
    if (q == null || _loading) return;
    setState(() {
      _loading = true;
      _selectedOptionId = optionId;
      _answerRevealed = true;
    });
    try {
      final updated = await ref.read(studyServiceProvider).updateProgress(
            sessionId: _session.id,
            questionId: q.id,
            selectedOptionId: optionId,
            currentQuestionIndex: _session.currentQuestionIndex,
          );
      if (mounted) setState(() => _session = updated);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitFlashcard(FlashcardAction action) async {
    final q = _currentQuestion;
    if (q == null || _loading) return;
    setState(() => _loading = true);
    try {
      final updated = await ref.read(studyServiceProvider).updateProgress(
            sessionId: _session.id,
            questionId: q.id,
            flashcardAction: action,
            answerRevealed: _answerRevealed,
            currentQuestionIndex: _session.currentQuestionIndex,
            isCompleted: _session.currentQuestionIndex + 1 >=
                _session.questionCount,
          );
      if (mounted) {
        setState(() {
          _session = updated;
          _answerRevealed = false;
          _selectedOptionId = null;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session.isCompleted) return _CompletedView(session: _session);

    final q = _currentQuestion;
    if (q == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text(_session.mode == StudySessionMode.flashcard
            ? 'Flashcards'
            : 'Self-Test'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _session.questionCount > 0
                ? _session.currentQuestionIndex / _session.questionCount
                : 0,
            backgroundColor: Colors.white12,
            color: const Color(0xFF6366F1),
          ),
        ),
      ),
      body: _session.mode == StudySessionMode.flashcard
          ? _FlashcardView(
              question: q,
              revealed: _answerRevealed,
              onReveal: () => setState(() => _answerRevealed = true),
              onAction: _submitFlashcard,
              loading: _loading,
            )
          : _SelfTestView(
              question: q,
              revealed: _answerRevealed,
              selectedOptionId: _selectedOptionId,
              onSelect: _submitSelfTest,
              loading: _loading,
            ),
    );
  }
}

class _FlashcardView extends StatelessWidget {
  final StudyQuestion question;
  final bool revealed;
  final VoidCallback onReveal;
  final void Function(FlashcardAction) onAction;
  final bool loading;

  const _FlashcardView({
    required this.question,
    required this.revealed,
    required this.onReveal,
    required this.onAction,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    question.text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  if (revealed && question.correctOptionId != null) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 16),
                    Text(
                      question.correctOptionId!,
                      style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (question.explanation != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        question.explanation!,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!revealed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onReveal,
                child: const Text('Show Answer'),
              ),
            )
          else
            Row(
              children: FlashcardAction.values.map((action) {
                final colors = {
                  FlashcardAction.again: Colors.red,
                  FlashcardAction.hard: Colors.orange,
                  FlashcardAction.good: Colors.blue,
                  FlashcardAction.easy: Colors.green,
                };
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors[action],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: loading ? null : () => onAction(action),
                      child: Text(action.apiValue,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _SelfTestView extends StatelessWidget {
  final StudyQuestion question;
  final bool revealed;
  final String? selectedOptionId;
  final void Function(String) onSelect;
  final bool loading;

  const _SelfTestView({
    required this.question,
    required this.revealed,
    required this.selectedOptionId,
    required this.onSelect,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.text,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ...question.options.map((opt) {
            Color? color;
            if (revealed) {
              if (opt.id == question.correctOptionId) {
                color = Colors.green.shade700;
              } else if (opt.id == selectedOptionId) {
                color = Colors.red.shade700;
              }
            }
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      color ?? const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (revealed || loading) ? null : () => onSelect(opt.id),
                child: Text(opt.text),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  final StudySession session;

  const _CompletedView({required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 72),
              const SizedBox(height: 20),
              const Text(
                'Session Complete!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '${session.correctCount} / ${session.questionCount} correct',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.go('/study'),
                child: const Text('Back to Study Hub'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
