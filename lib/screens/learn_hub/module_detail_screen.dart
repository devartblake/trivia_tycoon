import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dto/learning_dto.dart';
import '../../game/providers/learning_providers.dart';

class ModuleDetailScreen extends ConsumerWidget {
  final String moduleId;

  const ModuleDetailScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleAsync = ref.watch(moduleDetailProvider(moduleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Overview'),
      ),
      body: moduleAsync.when(
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
                  error.toString().contains('NOT_FOUND')
                      ? 'Module not found.'
                      : 'Could not load module.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.refresh(moduleDetailProvider(moduleId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (module) => _ModuleDetailBody(module: module),
      ),
    );
  }
}

class _ModuleDetailBody extends StatelessWidget {
  final ModuleDto module;

  const _ModuleDetailBody({required this.module});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = module.difficultyColour;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            module.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Category + difficulty row
          Wrap(
            spacing: 8,
            children: [
              _Chip(
                label: module.category,
                bgColor: theme.colorScheme.secondaryContainer,
                textColor: theme.colorScheme.onSecondaryContainer,
              ),
              _Chip(
                label: module.difficultyText,
                bgColor: color.withOpacity(0.15),
                textColor: color,
                borderColor: color,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            module.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              _StatTile(
                icon: Icons.menu_book_outlined,
                value: '${module.lessonCount}',
                label: 'Lessons',
              ),
              const SizedBox(width: 16),
              _StatTile(
                icon: Icons.star_outline,
                value: '+${module.rewardXp} XP',
                label: 'Reward',
              ),
              const SizedBox(width: 16),
              _StatTile(
                icon: Icons.monetization_on_outlined,
                value: '+${module.rewardCoins}',
                label: 'Coins',
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Start button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Learning'),
              onPressed: () =>
                  context.push('/learn-hub/module/${module.id}/lessons'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;

  const _Chip({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey.shade600)),
      ],
    );
  }
}
