import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../../game/models/skill_tree_category_colors.dart';
import '../../../game/models/skill_tree_graph.dart';
import '../../../game/providers/skill_cooldown_service_provider.dart';
import '../../../game/providers/skill_tree_provider.dart';
import '../../../game/providers/xp_provider.dart';
import '../../../game/services/skill_cooldown_service.dart';
import 'skill_effect_labels.dart';
import 'skill_node_widget.dart';

/// A rich modal bottom sheet showing full detail for a [SkillNode].
///
/// Show via [SkillNodeDetailSheet.show].
class SkillNodeDetailSheet extends ConsumerWidget {
  final SkillNode node;
  final SkillTreeGraph graph;
  final SkillTreeController controller;
  final SkillCooldownService cooldownService;

  const SkillNodeDetailSheet({
    super.key,
    required this.node,
    required this.graph,
    required this.controller,
    required this.cooldownService,
  });

  // ── Static show helper ────────────────────────────────────────────────────

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    SkillNode node,
  ) {
    final graph = ref.read(skillTreeProvider).graph;
    final ctrl = ref.read(skillTreeProvider.notifier);
    final cooldowns = ref.read(skillCooldownServiceProvider);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkillNodeDetailSheet(
        node: node,
        graph: graph,
        controller: ctrl,
        cooldownService: cooldowns,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor =
        SkillTreeCategoryColors.categoryColors[node.category] ??
            Colors.blueGrey;
    final playerXP = ref.watch(playerXPProvider);
    final onCooldown = cooldownService.isOnCooldown(node.id);
    final remaining = onCooldown ? cooldownService.remaining(node.id) : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header row: mini hex preview + title + category chip
              _buildHeader(context, categoryColor)
                  .animate()
                  .slideY(begin: 0.15, duration: 250.ms, curve: Curves.easeOutCubic)
                  .fadeIn(duration: 200.ms),

              const SizedBox(height: 14),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),

              // Tier dots + trigger tag
              _buildMeta(categoryColor)
                  .animate()
                  .fadeIn(duration: 200.ms, delay: 60.ms),

              const SizedBox(height: 14),

              // Description
              Text(
                node.description,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
              ).animate().fadeIn(duration: 200.ms, delay: 80.ms),

              const SizedBox(height: 20),

              // Effects section
              if (_visibleEffects.isNotEmpty) ...[
                _sectionHeader('EFFECTS'),
                const SizedBox(height: 8),
                ..._visibleEffects.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  final lbl = SkillEffectLabels.label(e.key, e.value);
                  if (lbl.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(right: 10, top: 2),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            lbl,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    )
                        .animate(delay: Duration(milliseconds: 60 + idx * 50))
                        .slideX(begin: 0.08, duration: 180.ms)
                        .fadeIn(duration: 160.ms),
                  );
                }),
                const SizedBox(height: 12),
              ],

              // Prerequisites section
              ..._buildPrerequisites(graph),

              const SizedBox(height: 20),

              // Cost + action button
              _buildActionRow(context, ref, categoryColor, playerXP, onCooldown, remaining),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<MapEntry<String, num>> get _visibleEffects => node.effects.entries
      .where((e) => !SkillEffectLabels.isHidden(e.key))
      .toList();

  Widget _buildHeader(BuildContext context, Color categoryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini hex node preview
        SkillNodeWidget(
          node: node,
          isUnlocked: node.unlocked,
          isSelected: false,
          size: SkillNodeSize.medium,
          categoryColor: categoryColor,
          cooldownService: cooldownService,
          onTap: null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                node.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              // Category chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  node.category.name.toUpperCase(),
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeta(Color categoryColor) {
    final maxTier = graph.maxTier.clamp(1, 6);
    final trigger = node.effectTrigger ?? 'passive';

    return Row(
      children: [
        // Tier dots
        const Text('Tier ', style: TextStyle(color: Colors.white54, fontSize: 12)),
        for (int i = 0; i <= maxTier; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= node.tier
                  ? categoryColor
                  : Colors.white12,
            ),
          ),
        const Spacer(),
        // Trigger tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            trigger == 'active' ? '▶ ACTIVE' : '◈ PASSIVE',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPrerequisites(SkillTreeGraph graph) {
    final prereqIds = graph.getPrerequisites(node.id);
    if (prereqIds.isEmpty) return [];

    return [
      _sectionHeader('REQUIRES'),
      const SizedBox(height: 8),
      ...prereqIds.map((id) {
        final prereq = graph.getNodeById(id);
        if (prereq == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                prereq.unlocked ? Icons.check_circle : Icons.lock,
                color: prereq.unlocked ? Colors.green : Colors.white38,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                prereq.title,
                style: TextStyle(
                  color: prereq.unlocked ? Colors.white : Colors.white54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(tier ${prereq.tier})',
                style: const TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 12),
    ];
  }

  Widget _buildActionRow(
    BuildContext context,
    WidgetRef ref,
    Color categoryColor,
    int playerXP,
    bool onCooldown,
    Duration? remaining,
  ) {
    // Determine button state
    final _ButtonState btnState = _resolveButtonState(
      playerXP: playerXP,
      onCooldown: onCooldown,
    );

    final String btnLabel = _buttonLabel(btnState, remaining);
    final bool enabled = btnState == _ButtonState.canUnlock ||
        btnState == _ButtonState.canUse;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Cost badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!node.unlocked)
                Row(
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${node.cost} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              if (!node.unlocked)
                Text(
                  'You have: $playerXP XP',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              if (node.unlocked && node.effectTrigger == 'active')
                const Text('Active skill', style: TextStyle(color: Colors.white54, fontSize: 12)),
              if (node.unlocked && node.effectTrigger != 'active')
                const Text('Passive — always active', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const Spacer(),
          // Action button
          FilledButton(
            onPressed: enabled
                ? () {
                    if (btnState == _ButtonState.canUnlock) {
                      controller.unlockSkill(node.id);
                    } else {
                      controller.useSkill(node.id);
                    }
                    Navigator.of(context).pop();
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: enabled ? categoryColor : Colors.white12,
              foregroundColor: enabled ? Colors.white : Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              btnLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  _ButtonState _resolveButtonState({
    required int playerXP,
    required bool onCooldown,
  }) {
    if (node.unlocked) {
      if (node.effectTrigger == 'active') {
        return onCooldown ? _ButtonState.onCooldown : _ButtonState.canUse;
      }
      return _ButtonState.alreadyUnlocked;
    }
    // Check prereqs
    final prereqIds = graph.getPrerequisites(node.id);
    final prereqsMet = prereqIds.isEmpty ||
        prereqIds.every((id) => graph.getNodeById(id)?.unlocked == true);
    if (!prereqsMet) return _ButtonState.prereqLocked;
    if (playerXP < node.cost) return _ButtonState.insufficientXP;
    return _ButtonState.canUnlock;
  }

  String _buttonLabel(_ButtonState state, Duration? remaining) {
    switch (state) {
      case _ButtonState.alreadyUnlocked:
        return '✓ Unlocked';
      case _ButtonState.canUse:
        return '▶ Use Skill';
      case _ButtonState.canUnlock:
        return 'Unlock — ${node.cost} XP';
      case _ButtonState.insufficientXP:
        return 'Need ${node.cost} XP';
      case _ButtonState.prereqLocked:
        final firstLocked = graph
            .getPrerequisites(node.id)
            .map(graph.getNodeById)
            .whereType<SkillNode>()
            .where((n) => !n.unlocked)
            .firstOrNull;
        return 'Requires: ${firstLocked?.title ?? '...'}';
      case _ButtonState.onCooldown:
        if (remaining == null) return 'Cooling down…';
        final mm = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
        final ss = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
        return 'Cooling down $mm:$ss';
    }
  }

  Widget _sectionHeader(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

enum _ButtonState {
  alreadyUnlocked,
  canUse,
  canUnlock,
  insufficientXP,
  prereqLocked,
  onCooldown,
}
