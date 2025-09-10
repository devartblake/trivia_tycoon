import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';

/// UI groups (high-level buckets)
enum SkillTreeGroupId { combat, enhancement, utility, advanced }

SkillTreeGroupId parseGroupId(String raw) {
  switch (raw.toLowerCase()) {
    case 'combat':
    case 'combat-focused':
    case 'combat_focused':
      return SkillTreeGroupId.combat;
    case 'enhancement':
      return SkillTreeGroupId.enhancement;
    case 'utility':
      return SkillTreeGroupId.utility;
    case 'advanced':
      return SkillTreeGroupId.advanced;
    default:
      return SkillTreeGroupId.utility;
  }
}

Color groupAccent(SkillTreeGroupId g) {
  switch (g) {
    case SkillTreeGroupId.combat: return const Color(0xFFFF4444); // red
    case SkillTreeGroupId.enhancement: return const Color(0xFFF39C12); // orange
    case SkillTreeGroupId.utility: return const Color(0xFF8E44AD); // purple
    case SkillTreeGroupId.advanced: return const Color(0xFFFFD700); // gold
  }
}

SkillCategory branchIdToCategory(String branchId) {
  switch (branchId.toLowerCase()) {
    case 'scholar': return SkillCategory.scholar;
    case 'strategist': return SkillCategory.strategist;
    case 'combat': return SkillCategory.combat;
    case 'xp': return SkillCategory.xp;
    case 'timer': return SkillCategory.timer;
    case 'combo': return SkillCategory.combo;
    case 'risk': return SkillCategory.risk;
    case 'luck': return SkillCategory.luck;
    case 'stealth': return SkillCategory.stealth;
    case 'knowledge': return SkillCategory.knowledge;
    case 'elite': return SkillCategory.elite;
    case 'wildcard': return SkillCategory.wildcard;
    case 'general': return SkillCategory.general;
    default: return SkillCategory.unknown;
  }
}

/// VM for a parsed "branch" section from JSON
class SkillBranchVM {
  final String branchId;
  final SkillTreeGroupId groupId;
  final String title;
  final String description;
  final Color accent;

  /// Raw node maps from JSON for convenience (id/title/description/cost/unlocked/requires/effects/etc)
  final List<Map<String, dynamic>> nodeMaps;

  SkillBranchVM({
    required this.branchId,
    required this.groupId,
    required this.title,
    required this.description,
    required this.accent,
    required this.nodeMaps,
  });

  int get totalNodes => nodeMaps.length;
  int get unlockedCount =>
      nodeMaps.where((m) => (m['unlocked'] == true)).length;

  double get progress => totalNodes == 0 ? 0 : unlockedCount / totalNodes;

  /// Build a SkillTreeGraph for this branch (assigns tiers from prerequisites)
  SkillTreeGraph toGraph() {
    final nodes = <SkillNode>[];
    final edges = <SkillEdge>[];

    // Build nodes
    for (final m in nodeMaps) {
      final id = m['id'] as String;
      final title = (m['title'] ?? id) as String;
      final desc = (m['description'] ?? '') as String;
      final cost = (m['cost'] ?? 1) as int;
      final unlocked = (m['unlocked'] ?? false) as bool;

      final effects = <String, num>{};
      if (m['effects'] is Map) {
        for (final e in (m['effects'] as Map).entries) {
          final k = e.key.toString();
          final v = e.value;
          if (v is num) effects[k] = v;
        }
      }

      nodes.add(SkillNode(
        id: id,
        title: title,
        description: desc,
        tier: 0, // temporary; we compute below
        cost: cost,
        category: branchIdToCategory(branchId),
        effects: effects,
        unlocked: unlocked,
        available: false,
      ));

      // Edges from requires
      final reqs = (m['requires'] as List?)?.cast<String>() ?? const <String>[];
      for (final req in reqs) {
        edges.add(SkillEdge(fromId: req, toId: id));
      }
    }

    // Assign tiers based on prerequisites (longest path)
    final byId = {for (final n in nodes) n.id: n};
    final incoming = {for (final n in nodes) n.id: <String>[]};
    for (final e in edges) {
      incoming[e.toId]!.add(e.fromId);
    }

    final memo = <String, int>{};
    int dfsTier(String id) {
      if (memo.containsKey(id)) return memo[id]!;
      final preds = incoming[id]!;
      final t = preds.isEmpty ? 0 : (preds.map(dfsTier).fold<int>(0, (a, b) => a > b ? a : b) + 1);
      memo[id] = t;
      return t;
    }

    for (final n in nodes) {
      final t = dfsTier(n.id);
      final idx = nodes.indexWhere((x) => x.id == n.id);
      nodes[idx] = n.copyWith(unlocked: n.unlocked).copyWith(unlocked: n.unlocked)
        ..tier; // no-op to “use” getter; we’ll rebuild:
    }
    // Rebuild with correct tier
    for (var i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final t = dfsTier(n.id);
      nodes[i] = SkillNode(
        id: n.id,
        title: n.title,
        description: n.description,
        tier: t,
        cost: n.cost,
        category: n.category,
        effects: n.effects,
        unlocked: n.unlocked,
        available: n.available,
      );
    }

    return SkillTreeGraph(nodes: nodes, edges: edges);
  }
}

/// Group VM (contains many branches)
class SkillTreeGroupVM {
  final SkillTreeGroupId id;
  final String title;
  final String description;
  final Color accent;
  final List<SkillBranchVM> branches;

  SkillTreeGroupVM({
    required this.id,
    required this.title,
    required this.description,
    required this.accent,
    required this.branches,
  });

  int get totalNodes => branches.fold(0, (a, b) => a + b.totalNodes);
  int get unlockedNodes => branches.fold(0, (a, b) => a + b.unlockedCount);
  double get progress => totalNodes == 0 ? 0 : unlockedNodes / totalNodes;
}
