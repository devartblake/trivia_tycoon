import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'widgets/skill_tree_view.dart';
import '../../game/providers/skill_tree_provider.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class SkillTreeScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const SkillTreeScreen({super.key, this.groupId});

  @override
  ConsumerState<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends ConsumerState<SkillTreeScreen> {
  String? _selectedGroupId;
  String _groupTitle = 'Pathways';
  SkillNodeFilterMode _filterMode = SkillNodeFilterMode.all;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId;
    _updateGroupTitle();

    // Load skills for the specific group if provided
    if (widget.groupId != null) {
      _loadSkillsForGroup(widget.groupId!);
    }
  }

  void _updateGroupTitle() {
    if (_selectedGroupId != null) {
      _groupTitle = _getGroupDisplayName(_selectedGroupId!);
    }
  }

  String _getGroupDisplayName(String groupId) {
    switch (groupId) {
      // Combat-Focused Groups
      case 'scholar':
        return 'Scholar Skills';
      case 'strategist':
        return 'Strategist Skills';
      case 'combat':
        return 'Combat Skills';

      // Enhancement Groups
      case 'xp':
        return 'XP Booster Skills';
      case 'timer':
        return 'Timer Skills';
      case 'combo':
        return 'Combo Skills';
      case 'risk':
        return 'Risk Skills';

      // Utility Groups
      case 'luck':
        return 'Luck Skills';
      case 'stealth':
        return 'Stealth Skills';
      case 'knowledge':
        return 'Knowledge Skills';

      // Advanced Groups
      case 'elite':
        return 'Elite Skills';
      case 'wildcard':
        return 'Wildcard Skills';
      case 'general':
        return 'General Skills';

      default:
        return 'Pathways';
    }
  }

  String _getGroupCategory(String groupId) {
    switch (groupId) {
      case 'scholar':
      case 'strategist':
      case 'combat':
        return 'combat_focused';
      case 'xp':
      case 'timer':
      case 'combo':
      case 'risk':
        return 'enhancement_branches';
      case 'luck':
      case 'stealth':
      case 'knowledge':
        return 'utility_branches';
      case 'elite':
      case 'wildcard':
      case 'general':
        return 'advanced_branches';
      default:
        return 'all';
    }
  }

  void _loadSkillsForGroup(String groupId) {
    // You can implement group-specific filtering logic here
    // For example, filter nodes by category or apply group-specific settings
    _filterSkillsByGroup(groupId);
  }

  void _filterSkillsByGroup(String groupId) {
    // Example filtering logic - you can customize this based on your needs
    switch (groupId) {
      case 'scholar':
        // Focus on scholar category skills
        _highlightSkillCategory('scholar');
        break;
      case 'strategist':
        _highlightSkillCategory('strategist');
        break;
      case 'combat':
        _highlightSkillCategory('combat');
        break;
      case 'xp':
        _highlightSkillCategory('xp');
        break;
      case 'timer':
        _highlightSkillCategory('timer');
        break;
      case 'combo':
        _highlightSkillCategory('combo');
        break;
      case 'risk':
        _highlightSkillCategory('risk');
        break;
      case 'luck':
        _highlightSkillCategory('luck');
        break;
      case 'stealth':
        _highlightSkillCategory('stealth');
        break;
      case 'knowledge':
        _highlightSkillCategory('knowledge');
        break;
      case 'elite':
        _highlightSkillCategory('elite');
        break;
      case 'wildcard':
        _highlightSkillCategory('wildcard');
        break;
      case 'general':
        _highlightSkillCategory('general');
        break;
    }
  }

  void _highlightSkillCategory(String category) {
    // Implement logic to highlight or filter skills of a specific category
    // This could involve updating the skill tree state or passing filters to SkillTreeView
    LogManager.debug('Highlighting skills in category: $category');
  }

  Color _getGroupColor(String groupId) {
    switch (_getGroupCategory(groupId)) {
      case 'combat_focused':
        return const Color(0xFFE74C3C); // Red
      case 'enhancement_branches':
        return const Color(0xFFF39C12); // Orange
      case 'utility_branches':
        return const Color(0xFF8E44AD); // Purple
      case 'advanced_branches':
        return const Color(0xFFFFD700); // Gold
      default:
        return const Color(0xFF15183A); // Default
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupColor = _selectedGroupId != null
        ? _getGroupColor(_selectedGroupId!)
        : const Color(0xFF15183A);

    return Scaffold(
      appBar: AppBar(
        title: Text(_groupTitle),
        backgroundColor: groupColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to skills nav screen
            context.go('/skills');
          },
        ),
        actions: [
          if (_selectedGroupId != null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showGroupFilter,
              tooltip: 'Filter Skills',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGroupInfo,
            tooltip: 'Group Info',
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D1021),
      body: Column(
        children: [
          // Group indicator banner (if specific group is selected)
          if (_selectedGroupId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: groupColor.withValues(alpha: 0.2),
                border: Border(
                  bottom: BorderSide(
                    color: groupColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getGroupIcon(_selectedGroupId!),
                    color: groupColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_getGroupCategory(_selectedGroupId!).replaceAll('_', ' ').toUpperCase()} GROUP',
                    style: TextStyle(
                      color: groupColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/skills'),
                    child: const Text(
                      'VIEW ALL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main skill tree view
          Expanded(
            child: SkillTreeView(
              filterMode: _filterMode,
              // When a specific group is selected, only show that category's nodes.
              categoryId: _selectedGroupId,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGroupIcon(String groupId) {
    switch (groupId) {
      case 'scholar':
        return Icons.school;
      case 'strategist':
        return Icons.psychology;
      case 'combat':
        return Icons.local_fire_department;
      case 'xp':
        return Icons.trending_up;
      case 'timer':
        return Icons.timer;
      case 'combo':
        return Icons.bolt;
      case 'risk':
        return Icons.casino;
      case 'luck':
        return Icons.stars;
      case 'stealth':
        return Icons.visibility_off;
      case 'knowledge':
        return Icons.library_books;
      case 'elite':
        return Icons.military_tech;
      case 'wildcard':
        return Icons.shuffle;
      case 'general':
        return Icons.balance;
      default:
        return Icons.account_tree;
    }
  }

  void _showGroupFilter() {
    final graph = ref.read(skillTreeProvider).graph;

    // Pre-compute counts for each filter mode
    int _count(SkillNodeFilterMode mode) => switch (mode) {
          SkillNodeFilterMode.all => graph.nodes.length,
          SkillNodeFilterMode.unlocked => graph.unlockedNodes.length,
          SkillNodeFilterMode.available => graph.availableNodes.length,
          SkillNodeFilterMode.locked =>
            graph.nodes.where((n) => !n.unlocked && !n.available).length,
        };

    // Use a StatefulBuilder so the radio updates immediately inside the sheet
    SkillNodeFilterMode sheetSelected = _filterMode;

    showModalBottomSheet<SkillNodeFilterMode>(
      context: context,
      backgroundColor: const Color(0xFF15183A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Filter Skills',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...SkillNodeFilterMode.values.map((mode) {
                final count = _count(mode);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Radio<SkillNodeFilterMode>(
                    value: mode,
                    groupValue: sheetSelected,
                    activeColor: mode.color,
                    onChanged: (v) {
                      if (v == null) return;
                      setSheetState(() => sheetSelected = v);
                      setState(() => _filterMode = v);
                      Navigator.pop(ctx);
                    },
                  ),
                  title: Row(
                    children: [
                      Icon(mode.icon, color: mode.color, size: 18),
                      const SizedBox(width: 8),
                      Text(mode.label,
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  subtitle: Text(
                    '$count skill${count == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  onTap: () {
                    setSheetState(() => sheetSelected = mode);
                    setState(() => _filterMode = mode);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15183A),
        title: Text(
          _getGroupDisplayName(_selectedGroupId ?? ''),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _getGroupDescription(_selectedGroupId ?? ''),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getGroupDescription(String groupId) {
    switch (groupId) {
      case 'scholar':
        return 'Knowledge-based skills that provide learning advantages, hints, and study time bonuses.';
      case 'strategist':
        return 'Tactical skills focused on planning, streaks, and lifeline management.';
      case 'combat':
        return 'Direct offensive abilities including answer elimination and disruption tools.';
      case 'xp':
        return 'Experience and progression bonuses to accelerate your growth.';
      case 'timer':
        return 'Time manipulation abilities to freeze timers and extend question time.';
      case 'combo':
        return 'Streak and scoring combinations to maximize your point potential.';
      case 'risk':
        return 'High-reward, high-risk abilities with double-or-nothing mechanics.';
      case 'luck':
        return 'RNG-based protection and second chances to save you from mistakes.';
      case 'stealth':
        return 'Concealment abilities to hide your progress and mislead opponents.';
      case 'knowledge':
        return 'Category-specific accuracy bonuses and trivia expertise.';
      case 'elite':
        return 'Master-tier abilities requiring prerequisites from other skill groups.';
      case 'wildcard':
        return 'Unpredictable effects that can change the game in unexpected ways.';
      case 'general':
        return 'Balanced abilities that provide moderate bonuses across multiple areas.';
      default:
        return 'Explore various skill trees to enhance your trivia gameplay.';
    }
  }
}
