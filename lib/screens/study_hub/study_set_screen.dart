import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dto/study_dto.dart';
import '../../core/services/study/study_service.dart';
import '../../game/providers/study_providers.dart';

class StudySetScreen extends ConsumerWidget {
  final String setId;

  const StudySetScreen({super.key, required this.setId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(studySetDetailProvider(Uri.decodeComponent(setId)));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: detailAsync.maybeWhen(
          data: (d) => Text(d.title),
          orElse: () => const Text('Study Set'),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (detail) => _StudySetBody(detail: detail),
      ),
    );
  }
}

class _StudySetBody extends ConsumerStatefulWidget {
  final StudySetDetail detail;

  const _StudySetBody({required this.detail});

  @override
  ConsumerState<_StudySetBody> createState() => _StudySetBodyState();
}

class _StudySetBodyState extends ConsumerState<_StudySetBody> {
  bool _starting = false;

  Future<void> _startSession(StudySessionMode mode) async {
    setState(() => _starting = true);
    try {
      final service = ref.read(studyServiceProvider);
      final session = await service.createSession(
        studySetId: widget.detail.id,
        mode: mode,
      );
      if (!mounted) return;
      context.push('/study/session/${session.id}', extra: session);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not start session: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          detail.description,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          '${detail.questionCount} questions',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _StartButton(
                label: 'Flashcards',
                icon: Icons.flip,
                color: const Color(0xFF6366F1),
                loading: _starting,
                onTap: () => _startSession(StudySessionMode.flashcard),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StartButton(
                label: 'Self-Test',
                icon: Icons.quiz,
                color: const Color(0xFF10B981),
                loading: _starting,
                onTap: () => _startSession(StudySessionMode.selfTest),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Questions',
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...detail.questions.asMap().entries.map(
              (e) => _QuestionPreviewTile(index: e.key, question: e.value),
            ),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _StartButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _QuestionPreviewTile extends StatelessWidget {
  final int index;
  final StudyQuestion question;

  const _QuestionPreviewTile({required this.index, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question.text}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          if (question.correctOptionId != null) ...[
            const SizedBox(height: 6),
            Text(
              'Answer: ${question.correctOptionId}',
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
