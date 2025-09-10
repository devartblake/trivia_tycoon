import 'package:flutter/material.dart';
import 'package:trivia_tycoon/game/models/search.dart';
import '../../screens/skills_tree/repository/skill_tree_nav_repository.dart';

abstract class SearchProvider {
  Future<List<SearchResult>> search(String query, SearchFilter filter);
  SearchCategory get category;
  bool get isEnabled;
}

class SkillSearchProvider implements SearchProvider {
  final SkillTreeNavRepository skillRepo;

  SkillSearchProvider(this.skillRepo);

  @override
  SearchCategory get category => SearchCategory.skills;

  @override
  bool get isEnabled => true;

  @override
  Future<List<SearchResult>> search(String query, SearchFilter filter) async {
    if (!filter.categories.contains(SearchCategory.skills)) {
      return [];
    }

    final groups = await skillRepo.load();
    final results = <SearchResult>[];
    final queryLower = query.toLowerCase();

    for (final group in groups) {
      for (final branch in group.branches) {
        for (final nodeMap in branch.nodeMaps) {
          final title = (nodeMap['title'] ?? '').toString();
          final description = (nodeMap['description'] ?? '').toString();

          if (_matchesQuery(queryLower, title, description)) {
            results.add(SearchResult(
              id: nodeMap['id'] ?? '',
              title: title,
              description: description,
              type: SearchResultType.skill,
              category: SearchCategory.skills,
              subtitle: '${group.title} > ${branch.title}',
              icon: _getSkillIcon(branch.branchId),
              color: group.accent,
              navigationRoute: '/skill-tree/${branch.branchId}',
              relevanceScore: _calculateRelevance(queryLower, title, description),
              metadata: {
                'unlocked': nodeMap['unlocked'] ?? false,
                'cost': nodeMap['cost'] ?? 0,
                'branchId': branch.branchId,
                'groupId': group.id.name,
              },
            ));
          }
        }
      }
    }

    return results;
  }

  IconData _getSkillIcon(String branchId) {
    // Implementation matches your existing _getBranchIcon method
    switch (branchId.toLowerCase()) {
      case 'scholar': return Icons.school;
      case 'strategist': return Icons.psychology;
      case 'combat': return Icons.local_fire_department;
    // ... other cases
      default: return Icons.account_tree;
    }
  }

  bool _matchesQuery(String query, String title, String description) {
    return title.toLowerCase().contains(query) ||
        description.toLowerCase().contains(query);
  }

  int _calculateRelevance(String query, String title, String description) {
    int score = 0;
    final titleLower = title.toLowerCase();
    final descLower = description.toLowerCase();

    if (titleLower == query) score += 100;
    else if (titleLower.startsWith(query)) score += 80;
    else if (titleLower.contains(query)) score += 60;

    if (descLower.startsWith(query)) score += 40;
    else if (descLower.contains(query)) score += 20;

    return score;
  }
}

class NavigationSearchProvider implements SearchProvider {
  @override
  SearchCategory get category => SearchCategory.settings;

  @override
  bool get isEnabled => true;

  @override
  Future<List<SearchResult>> search(String query, SearchFilter filter) async {
    final navigationItems = [
      {
        'title': 'Settings',
        'description': 'App settings and preferences',
        'route': '/settings',
        'icon': Icons.settings,
      },
      {
        'title': 'Profile',
        'description': 'View and edit your profile',
        'route': '/profile',
        'icon': Icons.person,
      },
      {
        'title': 'Leaderboard',
        'description': 'View rankings and scores',
        'route': '/leaderboard',
        'icon': Icons.leaderboard,
      },
      {
        'title': 'Store',
        'description': 'Purchase items and upgrades',
        'route': '/store',
        'icon': Icons.store,
      },
      {
        'title': 'Help',
        'description': 'Get help and support',
        'route': '/help',
        'icon': Icons.help,
      },
    ];

    final results = <SearchResult>[];
    final queryLower = query.toLowerCase();

    for (final item in navigationItems) {
      final title = item['title'] as String;
      final description = item['description'] as String;

      if (title.toLowerCase().contains(queryLower) ||
          description.toLowerCase().contains(queryLower)) {
        results.add(SearchResult(
          id: 'nav_${item['route']}',
          title: title,
          description: description,
          type: SearchResultType.navigation,
          category: SearchCategory.settings,
          icon: item['icon'] as IconData,
          navigationRoute: item['route'] as String,
          relevanceScore: _calculateRelevance(queryLower, title, description),
        ));
      }
    }

    return results;
  }

  int _calculateRelevance(String query, String title, String description) {
    // Same logic as SkillSearchProvider
    int score = 0;
    final titleLower = title.toLowerCase();

    if (titleLower == query) score += 100;
    else if (titleLower.startsWith(query)) score += 80;
    else if (titleLower.contains(query)) score += 60;

    return score;
  }
}