import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dto/learning_dto.dart';
import '../../game/providers/learning_providers.dart';
import 'widgets/module_card.dart';

class LearnHubScreen extends ConsumerStatefulWidget {
  const LearnHubScreen({super.key});

  @override
  ConsumerState<LearnHubScreen> createState() => _LearnHubScreenState();
}

class _LearnHubScreenState extends ConsumerState<LearnHubScreen> {
  int? _selectedDifficulty; // null = show all

  static const _difficulties = [
    (value: 1, label: 'Easy'),
    (value: 2, label: 'Medium'),
    (value: 3, label: 'Hard'),
    (value: 4, label: 'Expert'),
  ];

  @override
  Widget build(BuildContext context) {
    final playerIdAsync = ref.watch(currentPlayerIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Hub'),
      ),
      body: playerIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildModuleList(null),
        data: (playerId) => _buildModuleList(playerId),
      ),
    );
  }

  Widget _buildModuleList(String? playerId) {
    final modulesAsync = _selectedDifficulty == null
        ? ref.watch(modulesProvider(playerId))
        : ref.watch(modulesByDifficultyProvider(
            '${playerId ?? ''}|$_selectedDifficulty'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DifficultyFilterBar(
          selected: _selectedDifficulty,
          difficulties: _difficulties,
          onSelected: (value) => setState(() => _selectedDifficulty = value),
        ),
        Expanded(
          child: modulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load modules.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.refresh(modulesProvider(null)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (modules) => modules.isEmpty
                ? const Center(
                    child: Text('No modules found.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      return ModuleCard(
                        module: module,
                        onTap: () =>
                            context.push('/learn-hub/module/${module.id}'),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _DifficultyFilterBar extends StatelessWidget {
  final int? selected;
  final List<({int value, String label})> difficulties;
  final void Function(int? value) onSelected;

  const _DifficultyFilterBar({
    required this.selected,
    required this.difficulties,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _chip(
            context,
            label: 'All',
            isSelected: selected == null,
            color: Colors.blueGrey,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...difficulties.map((d) {
            final color = difficultyColor(d.value);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(
                context,
                label: d.label,
                isSelected: selected == d.value,
                color: color,
                onTap: () => onSelected(selected == d.value ? null : d.value),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
