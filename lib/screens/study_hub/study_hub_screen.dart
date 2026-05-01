import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dto/study_dto.dart';
import '../../game/providers/learning_providers.dart' show currentPlayerIdProvider;
import '../../game/providers/study_providers.dart';
import '../../personalization/widgets/recommended_for_you_section.dart';

class StudyHubScreen extends ConsumerWidget {
  const StudyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendedAsync = ref.watch(recommendedStudySetsProvider);
    final allAsync = ref.watch(studySetsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('Study Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(studySetsProvider);
              ref.invalidate(recommendedStudySetsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studySetsProvider);
          ref.invalidate(recommendedStudySetsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PersonalizationRecommendations(),
            _SectionHeader(
              title: 'Recommended',
              icon: Icons.auto_awesome,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 8),
            recommendedAsync.when(
              loading: () => const _LoadingRow(),
              error: (e, _) => _ErrorRow(message: e.toString()),
              data: (sets) => _StudySetRow(sets: sets),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'All Study Sets',
              icon: Icons.library_books,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 8),
            allAsync.when(
              loading: () => const _LoadingRow(),
              error: (e, _) => _ErrorRow(message: e.toString()),
              data: (sets) => _StudySetList(sets: sets),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;

  const _ErrorRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Failed to load: $message',
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}

class _StudySetRow extends StatelessWidget {
  final List<StudySetListItem> sets;

  const _StudySetRow({required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) {
      return const Text('No sets available.',
          style: TextStyle(color: Colors.white54));
    }
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _StudySetCard(item: sets[i], compact: true),
      ),
    );
  }
}

class _StudySetList extends StatelessWidget {
  final List<StudySetListItem> sets;

  const _StudySetList({required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No study sets found.',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }
    return Column(
      children: sets.map((s) => _StudySetCard(item: s)).toList(),
    );
  }
}

class _StudySetCard extends StatelessWidget {
  final StudySetListItem item;
  final bool compact;

  const _StudySetCard({required this.item, this.compact = false});

  Color get _kindColor => switch (item.kind) {
        'Favorites' => const Color(0xFFF59E0B),
        'DueReview' => const Color(0xFFEF4444),
        'WeakArea' => const Color(0xFFEC4899),
        'Custom' => const Color(0xFF8B5CF6),
        _ => const Color(0xFF10B981),
      };

  IconData get _kindIcon => switch (item.kind) {
        'Favorites' => Icons.star,
        'DueReview' => Icons.schedule,
        'WeakArea' => Icons.trending_up,
        'Custom' => Icons.edit_note,
        _ => Icons.category,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/study/set/${Uri.encodeComponent(item.id)}'),
      child: Container(
        width: compact ? 160 : double.infinity,
        margin: compact ? null : const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kindColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_kindIcon, color: _kindColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  item.kind,
                  style: TextStyle(
                      color: _kindColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${item.questionCount} questions',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Personalization recommendations strip ─────────────────────────────────────

class _PersonalizationRecommendations extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncId = ref.watch(currentPlayerIdProvider);
    return asyncId.when(
      data: (id) {
        if (id == null || id.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RecommendedForYouSection(
            playerId: id,
            filterType: 'learning_module',
            sectionTitle: 'Personalised for You',
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
