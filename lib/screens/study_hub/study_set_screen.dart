import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dto/study_dto.dart';
import '../../game/providers/study_providers.dart';

class StudySetScreen extends ConsumerWidget {
  final String setId;

  const StudySetScreen({super.key, required this.setId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(studySetDetailProvider(Uri.decodeComponent(setId)));
    final isCustomSet = detailAsync.valueOrNull?.kind == 'Custom';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: detailAsync.maybeWhen(
          data: (d) => Text(d.title),
          orElse: () => const Text('Study Set'),
        ),
        actions: [
          if (isCustomSet)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push('/study/set/${Uri.encodeComponent(setId)}/edit'),
            ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (detail) => _StudySetBody(detail: detail, rawSetId: setId),
      ),
    );
  }
}

class _StudySetBody extends ConsumerStatefulWidget {
  final StudySetDetail detail;
  final String rawSetId;

  const _StudySetBody({required this.detail, required this.rawSetId});

  @override
  ConsumerState<_StudySetBody> createState() => _StudySetBodyState();
}

class _StudySetBodyState extends ConsumerState<_StudySetBody> {
  bool _starting = false;

  Future<void> _startSession(StudySessionMode mode) async {
    final setId = widget.detail.id;
    final activeSessions = ref.read(activeStudySessionsProvider);

    // If there's an active session for this set, offer to resume or start fresh
    if (activeSessions.containsKey(setId)) {
      final existingSessionId = activeSessions[setId]!;
      final resume = await _showResumeDialog(existingSessionId);
      if (!mounted) return;
      if (resume == null) return; // User dismissed
      if (resume) {
        context.push('/study/session/$existingSessionId');
        return;
      }
      // Start fresh — clear old session entry
      ref
          .read(activeStudySessionsProvider.notifier)
          .update((s) => Map.from(s)..remove(setId));
    }

    setState(() => _starting = true);
    try {
      final service = ref.read(studyServiceProvider);
      final session = await service.createSession(
        studySetId: setId,
        mode: mode,
      );
      // Track the new session for future resume
      ref
          .read(activeStudySessionsProvider.notifier)
          .update((s) => {...s, setId: session.id});
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

  Future<bool?> _showResumeDialog(String sessionId) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF15183A),
        title: const Text(
          'Resume session?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You have an unfinished session for this set.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Start New',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (detail.description.isNotEmpty) ...[
          Text(
            detail.description,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
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

class _QuestionPreviewTile extends ConsumerWidget {
  final int index;
  final StudyQuestion question;

  const _QuestionPreviewTile({required this.index, required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorited =
        ref.watch(favoritedQuestionIdsProvider).contains(question.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
                    style:
                        const TextStyle(color: Color(0xFF10B981), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          // Favorite toggle
          GestureDetector(
            onTap: () {
              final notifier = ref.read(favoritedQuestionIdsProvider.notifier);
              final service = ref.read(studyServiceProvider);
              if (favorited) {
                notifier.update((s) => {...s}..remove(question.id));
                service.removeFavorite(question.id);
              } else {
                notifier.update((s) => {...s, question.id});
                service.addFavorite(question.id);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                favorited ? Icons.favorite : Icons.favorite_border,
                color: favorited ? const Color(0xFFF59E0B) : Colors.white38,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
