import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../game/controllers/skill_tree_controller.dart';
import '../../../ui_components/hex_grid/widgets/hex_nav_button.dart';
import '../../../ui_components/hex_grid/math/hex_orientation.dart';
import '../../game/models/skill_tree_nav_models.dart';
import '../../game/providers/skill_tree_nav_providers.dart';
import '../../ui_components/hex_grid/widgets/mini_hex_preview.dart';

class SkillTreeNavScreen extends ConsumerStatefulWidget {
  const SkillTreeNavScreen({super.key});

  @override
  ConsumerState<SkillTreeNavScreen> createState() => _SkillTreeNavScreenState();
}

class _SkillTreeNavScreenState extends ConsumerState<SkillTreeNavScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _deepLinkToBranchStep(String branchId, {int initialStep = 0, bool showPath = true}) {
    context.push('/skill-tree/$branchId?step=$initialStep&showPath=${showPath ? 1 : 0}');
  }

  Color parseHex(String hex, {Color fallback = const Color(0xFF555555)}) {
    try {
      final v = hex.replaceAll('#', '');
      return Color(int.parse('FF$v', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillTreeState = ref.watch(skillTreeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1021),
      appBar: _buildAppBar(context, skillTreeState),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupGrid('combat_focused'),
                _buildGroupGrid('enhancement_branches'),
                _buildGroupGrid('utility_branches'),
                _buildGroupGrid('advanced_branches'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, SkillTreeState state) {
    return AppBar(
      backgroundColor: const Color(0xFF15183A),
      elevation: 0,
      title: const Text(
        'Skill Trees',
        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      actions: [
        const SizedBox(width: 8),

        // Search Button
        IconButton(
          onPressed: () => _showSearchDialog(context),
          icon: const Icon(Icons.search, color: Colors.white),
        ),

        // XP Display
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF27AE60),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'XP: ${state.playerPoints}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),

        // Close Button
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF15183A),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicatorColor: const Color(0xFF6EE7F9),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Combat'),
          Tab(text: 'Enhancement'),
          Tab(text: 'Utility'),
          Tab(text: 'Advanced'),
        ],
      ),
    );
  }

  Widget _buildGroupGrid(String groupType) {
    final groups = _getGroupsForType(groupType);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return _buildGroupCard(group);
        },
      ),
    );
  }

  Widget _buildGroupCard(SkillGroupData group) {
    final bg = parseHex(group.color);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, bg.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSkillTree(group.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8), // Further reduced padding
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use available height to determine if we can fit all elements
                final availableHeight = constraints.maxHeight;
                final shouldShowPreview = availableHeight > 120; // Only show preview if enough space

                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: hex badge + route icon
                    Row(
                      children: [
                        HexNavButton(
                          size: HexButtonSize.small, // Use small preset
                          orientation: HexOrientation.pointy,
                          icon: Icon(group.icon, color: Colors.white),
                          gradient: LinearGradient(
                            colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0.10)],
                          ),
                          borderColor: Colors.white.withOpacity(0.6),
                          badgeCount: group.availableSkills,
                        ),
                        const Spacer(),
                        // Compact route icon
                        GestureDetector(
                          onTap: () => _deepLinkToBranchStep(group.id, initialStep: 0, showPath: true),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.alt_route, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),

                    // Flexible spacer
                    if (shouldShowPreview) const SizedBox(height: 2),

                    // Title and branch count (always visible)
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            group.title,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${group.branchCount} branches',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 9),
                          ),
                        ],
                      ),
                    ),

                    // Conditional preview (only if space allows)
                    if (shouldShowPreview) ...[
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 20, // Even smaller height
                        child: Stack(
                          children: [
                            MiniHexBranchPreview(
                              branchId: group.id,
                              baseColor: bg,
                              textColor: Colors.white,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _showAutoPath(context, group.id),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Tooltip(
                                    message: 'Open preview',
                                    child: Icon(Icons.open_in_full, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Flexible spacer
                    if (shouldShowPreview) const SizedBox(height: 2),

                    // Progress (always visible, compact)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildProgressIndicator(group.progressPercent),
                        const SizedBox(height: 1),
                        Text(
                          '${group.progressPercent}%',
                          style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    // Compact auto-path button (always visible)
                    GestureDetector(
                      onTap: () => _showAutoPath(context, group.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.alt_route, size: 10, color: Colors.white),
                            SizedBox(width: 2),
                            Text('Auto-path', style: TextStyle(fontSize: 8, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int percent) {
    return Container(
      width: double.infinity,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percent / 100.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  // Added missing _getBranchIcon method
  IconData _getBranchIcon(String branchId) {
    switch (branchId.toLowerCase()) {
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

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15183A),
        title: const Text('Search Skills', style: TextStyle(color: Colors.white)),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter skill name...',
            hintStyle: TextStyle(color: Colors.white60),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: (query) {
            Navigator.pop(context);
            _performSearch(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    _performInAppSkillSearch(query);
  }

  void _performInAppSkillSearch(String query) async {
    if (query.trim().isEmpty) return;

    final skillTreeGroupsAsync = ref.read(skillTreeGroupsProvider);

    skillTreeGroupsAsync.when(
      loading: () => _showSearchResults([]),
      error: (error, stack) => _showSearchError(),
      data: (groups) {
        final results = _searchSkills(query.trim(), groups);
        _showSearchResults(results);
      },
    );
  }

  List<SkillSearchResult> _searchSkills(String query, List<SkillTreeGroupVM> groups) {
    final results = <SkillSearchResult>[];
    final queryLower = query.toLowerCase();

    for (final group in groups) {
      for (final branch in group.branches) {
        for (final nodeMap in branch.nodeMaps) {
          final title = (nodeMap['title'] ?? '').toString().toLowerCase();
          final description = (nodeMap['description'] ?? '').toString().toLowerCase();
          final id = (nodeMap['id'] ?? '').toString();

          // Search in title, description, and effects
          bool matches = title.contains(queryLower) ||
              description.contains(queryLower);

          // Search in effects
          if (!matches && nodeMap['effects'] is Map) {
            final effects = nodeMap['effects'] as Map;
            for (final key in effects.keys) {
              if (key.toString().toLowerCase().contains(queryLower)) {
                matches = true;
                break;
              }
            }
          }

          if (matches) {
            results.add(SkillSearchResult(
              id: id,
              title: nodeMap['title'] ?? '',
              description: nodeMap['description'] ?? '',
              branchTitle: branch.title,
              groupTitle: group.title,
              branchId: branch.branchId,
              unlocked: nodeMap['unlocked'] ?? false,
              cost: nodeMap['cost'] ?? 0,
              relevanceScore: _calculateRelevance(queryLower, title, description),
            ));
          }
        }
      }
    }

    // Sort by relevance (title matches first, then description matches)
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  int _calculateRelevance(String query, String title, String description) {
    int score = 0;

    // Exact title match gets highest score
    if (title == query) score += 100;
    // Title starts with query
    else if (title.startsWith(query)) score += 80;
    // Title contains query
    else if (title.contains(query)) score += 60;

    // Description matches get lower scores
    if (description.startsWith(query)) score += 40;
    else if (description.contains(query)) score += 20;

    return score;
  }

  void _showSearchResults(List<SkillSearchResult> results) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15183A),
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Results (${results.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                child: Text(
                  'No skills found',
                  style: TextStyle(color: Colors.white60),
                ),
              )
                  : ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return _buildSearchResultCard(result);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(SkillSearchResult result) {
    return Card(
      color: const Color(0xFF1E2139),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getBranchIcon(result.branchId),
          color: result.unlocked ? Colors.green : Colors.orange,
        ),
        title: Text(
          result.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.description,
              style: const TextStyle(color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${result.groupTitle} > ${result.branchTitle}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              result.unlocked ? Icons.check_circle : Icons.lock,
              color: result.unlocked ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              'Cost: ${result.cost}',
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ],
        ),
        onTap: () {
          context.pop();
          context.push('/skill-tree/${result.branchId}?step=0&showPath=1');
        },
      ),
    );
  }

  void _showSearchError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error loading skills for search'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToSkillTree(String groupId) {
    // Navigate to specific skill tree view using go_router
    context.push('/skill-tree/$groupId');
  }

  List<SkillGroupData> _getGroupsForType(String groupType) {
    switch (groupType) {
      case 'combat_focused':
        return [
          SkillGroupData(
            id: 'scholar',
            title: 'Scholar',
            color: '#4A90E2',
            icon: Icons.school,
            branchCount: 3,
            progressPercent: 45,
            availableSkills: 2,
          ),
          SkillGroupData(
            id: 'strategist',
            title: 'Strategist',
            color: '#9B59B6',
            icon: Icons.psychology,
            branchCount: 4,
            progressPercent: 38,
            availableSkills: 3,
          ),
          SkillGroupData(
            id: 'combat',
            title: 'Combat',
            color: '#E74C3C',
            icon: Icons.local_fire_department,
            branchCount: 3,
            progressPercent: 22,
            availableSkills: 1,
          ),
        ];
      case 'enhancement_branches':
        return [
          SkillGroupData(
            id: 'xp',
            title: 'XP Booster',
            color: '#27AE60',
            icon: Icons.trending_up,
            branchCount: 4,
            progressPercent: 67,
            availableSkills: 4,
          ),
          SkillGroupData(
            id: 'timer',
            title: 'Timer',
            color: '#3498DB',
            icon: Icons.timer,
            branchCount: 3,
            progressPercent: 33,
            availableSkills: 1,
          ),
          SkillGroupData(
            id: 'combo',
            title: 'Combo',
            color: '#E67E22',
            icon: Icons.bolt,
            branchCount: 3,
            progressPercent: 55,
            availableSkills: 2,
          ),
          SkillGroupData(
            id: 'risk',
            title: 'Risk',
            color: '#C0392B',
            icon: Icons.casino,
            branchCount: 3,
            progressPercent: 11,
            availableSkills: 0,
          ),
        ];
      case 'utility_branches':
        return [
          SkillGroupData(
            id: 'luck',
            title: 'Luck',
            color: '#F1C40F',
            icon: Icons.stars,
            branchCount: 3,
            progressPercent: 29,
            availableSkills: 1,
          ),
          SkillGroupData(
            id: 'stealth',
            title: 'Stealth',
            color: '#34495E',
            icon: Icons.visibility_off,
            branchCount: 3,
            progressPercent: 0,
            availableSkills: 1,
          ),
          SkillGroupData(
            id: 'knowledge',
            title: 'Knowledge',
            color: '#16A085',
            icon: Icons.library_books,
            branchCount: 3,
            progressPercent: 15,
            availableSkills: 0,
          ),
        ];
      case 'advanced_branches':
        return [
          SkillGroupData(
            id: 'elite',
            title: 'Elite',
            color: '#FFD700',
            icon: Icons.military_tech,
            branchCount: 3,
            progressPercent: 0,
            availableSkills: 0,
          ),
          SkillGroupData(
            id: 'wildcard',
            title: 'Wildcard',
            color: '#8E44AD',
            icon: Icons.shuffle,
            branchCount: 2,
            progressPercent: 25,
            availableSkills: 1,
          ),
          SkillGroupData(
            id: 'general',
            title: 'General',
            color: '#7F8C8D',
            icon: Icons.balance,
            branchCount: 2,
            progressPercent: 50,
            availableSkills: 1,
          ),
        ];
      default:
        return [];
    }
  }
}

class SkillGroupData {
  final String id;
  final String title;
  final String color;
  final IconData icon;
  final int branchCount;
  final int progressPercent;
  final int availableSkills;

  SkillGroupData({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
    required this.branchCount,
    required this.progressPercent,
    required this.availableSkills,
  });
}

class SkillSearchResult {
  final String id;
  final String title;
  final String description;
  final String branchTitle;
  final String groupTitle;
  final String branchId;
  final bool unlocked;
  final int cost;
  final int relevanceScore;

  SkillSearchResult({
    required this.id,
    required this.title,
    required this.description,
    required this.branchTitle,
    required this.groupTitle,
    required this.branchId,
    required this.unlocked,
    required this.cost,
    required this.relevanceScore,
  });
}

extension _AutoPathSheet on _SkillTreeNavScreenState {
  void _showAutoPath(BuildContext context, String branchId, {int initialStep = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF15183A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool highlight = true;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24, borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Auto-Path Preview',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  // Larger read-only preview
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: const Color(0xFF0D1021),
                        child: MiniHexBranchPreview(
                          branchId: branchId,
                          baseColor: Colors.white24,
                          textColor: Colors.white,
                          highlightPath: highlight, // Now using the parameter
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Highlight toggle
                  Row(
                    children: [
                      const Icon(Icons.visibility, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Highlight full path',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      Switch(
                        value: highlight,
                        onChanged: (v) => setSheetState(() => highlight = v),
                        activeColor: Colors.cyanAccent,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Start button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.alt_route, size: 18),
                      label: const Text('Start Auto-Path'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6EE7F9),
                        foregroundColor: const Color(0xFF0D1021),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deepLinkToBranchStep(branchId, initialStep: initialStep, showPath: highlight);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}