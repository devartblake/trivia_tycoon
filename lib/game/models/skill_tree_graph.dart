import 'package:flutter/foundation.dart';

/// Skill categories used for classification and styling
enum SkillCategory {
  scholar,
  strategist,
  xp,
  risk,
  luck,
  combo,
  elite,
  timer,
  combat,
  stealth,
  category,
  wildcard,
  unknown,
  general,
  knowledge,
}

extension SkillCategoryExtension on SkillCategory {
  String get groupId {
    switch (this) {
      case SkillCategory.scholar:
      case SkillCategory.strategist:
      case SkillCategory.combat:
        return 'combat_focused';
      case SkillCategory.xp:
      case SkillCategory.timer:
      case SkillCategory.combo:
      case SkillCategory.risk:
        return 'enhancement_branches';
      case SkillCategory.luck:
      case SkillCategory.stealth:
      case SkillCategory.knowledge:
        return 'utility_branches';
      case SkillCategory.elite:
      case SkillCategory.wildcard:
      case SkillCategory.general:
        return 'advanced_branches';
      default:
        return 'unknown';
    }
  }

  String get brandId {
    return name;
  }
}

/// Types of skill effects used for triggering behavior
enum SkillEffectType {
  xpBoost,
  instantCoins,
  doublePoints,
  unlockCategory,
  bonusSpin,
  custom, // fallback for Map-based effects
}


/// Represents a node in the skill tree
class SkillNode {
  final String id;
  final String title;
  final String description;
  final int tier; // 0..n (row)
  final int cost; // XP or tokens
  final SkillCategory category;
  final Map<String, num> effects; // e.g. {"timeBonusSec": 5, "sportsScoreBoost": 0.1}
  final Duration? cooldown;
  final DateTime? lastUsed;
  final String? branchId;
  bool unlocked;
  bool available;

  /// Optional for structured effects
  final SkillEffectType? effectType;
  final double? effectValue;
  final int? duration; // in seconds or turns
  final String? effectTarget; // e.g. category name
  final String? effectTrigger; // e.g. skill name

  SkillNode({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.cost,
    required this.category,
    required this.effects,
    this.cooldown,
    this.lastUsed,
    this.branchId,
    this.unlocked = false,
    this.available = false,
    this.effectType,
    this.effectValue,
    this.duration,
    this.effectTarget,
    this.effectTrigger,
  });

  factory SkillNode.fromJson(Map<String, dynamic> json) {
    // Parse category from string
    SkillCategory category = SkillCategory.unknown;
    final categoryStr = json['category'] as String?;
    if (categoryStr != null) {
      try {
        category = SkillCategory.values.firstWhere(
              (e) => e.name == categoryStr,
          orElse: () => SkillCategory.unknown,
        );
      } catch (_) {
        category = SkillCategory.unknown;
      }
    }

    // Parse effect type from string
    SkillEffectType? effectType;
    final effectTypeStr = json['effectType'] as String?;
    if (effectTypeStr != null) {
      try {
        effectType = SkillEffectType.values.firstWhere(
              (e) => e.name == effectTypeStr,
          orElse: () => SkillEffectType.custom,
        );
      } catch (_) {
        effectType = SkillEffectType.custom;
      }
    }

    // Parse cooldown from milliseconds
    Duration? cooldown;
    final cooldownMs = json['cooldown'] as int?;
    if (cooldownMs != null) {
      cooldown = Duration(milliseconds: cooldownMs);
    }

    // Parse effects map
    final effects = <String, num>{};
    final effectsJson = json['effects'] as Map<String, dynamic>?;
    if (effectsJson != null) {
      for (final entry in effectsJson.entries) {
        if (entry.value is num) {
          effects[entry.key] = entry.value as num;
        } else if (entry.value is bool) {
          effects[entry.key] = (entry.value as bool) ? 1 : 0;
        }
      }
    }

    return SkillNode(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tier: json['tier'] ?? 0,
      cost: json['cost'] ?? 0,
      category: category,
      effects: effects,
      cooldown: cooldown,
      lastUsed: null, // Will be set when skill is used
      branchId: json['branchId'] as String?,
      unlocked: json['unlocked'] ?? false,
      available: json['available'] ?? false,
      effectType: effectType,
      effectValue: (json['effectValue'] as num?)?.toDouble(),
      duration: json['duration'] as int?,
      effectTarget: json['effectTarget'] as String?,
      effectTrigger: json['effectTrigger'] as String?,
    );
  }

  SkillNode copyWith({bool? unlocked, bool? available, DateTime? lastUsed}) =>
      SkillNode(
        id: id, title: title,
        description: description,
        tier: tier,
        cost: cost,
        category: category,
        effects: effects,
        cooldown: cooldown,
        lastUsed: lastUsed ?? this.lastUsed,
        branchId: branchId,
        unlocked: unlocked ?? this.unlocked,
        available: available ?? this.available,
        effectType: effectType,
        effectValue: effectValue,
        duration: duration,
        effectTarget: effectTarget,
        effectTrigger: effectTrigger,
      );
}

/// Extension for cooldown management
extension SkillNodeCooldown on SkillNode {
  bool get isOnCooldown {
    if (cooldown == null || lastUsed == null) return false;
    return DateTime.now().difference(lastUsed!) < cooldown!;
  }

  Duration? get remainingCooldown {
    if (!isOnCooldown) return null;
    final elapsed = DateTime.now().difference(lastUsed!);
    return cooldown! - elapsed;
  }

  bool get canUse => unlocked && !isOnCooldown;
}

/// Represents an edge in the skill tree, connects two skill nodes
class SkillEdge {
  final String fromId;
  final String toId;

  const SkillEdge({required this.fromId, required this.toId});

  factory SkillEdge.fromJson(Map<String, dynamic> json) {
    return SkillEdge(
      fromId: json['fromId'] ?? '',
      toId: json['toId'] ?? '',
    );
  }
}

/// Represents the entire skill tree graph of skill nodes and edges
class SkillTreeGraph {
  final List<SkillNode> nodes;
  final List<SkillEdge> edges;
  final Map<String, SkillGroup>? groups;

  const SkillTreeGraph({required this.nodes, required this.edges,this.groups});

  Map<String, SkillNode> get byId => {for (final n in nodes) n.id: n};
  Iterable<SkillNode> tier(int t) => nodes.where((n) => n.tier == t);
  int get maxTier => nodes.fold<int>(0, (m, n) => n.tier > m ? n.tier : m);

  SkillNode? getNodeById(String id) {
    try {
      return nodes.firstWhere((node) => node.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get nodes by group ID
  Iterable<SkillNode> nodesInGroup(String groupId) {
    return nodes.where((n) => n.category.groupId == groupId);
  }

  /// Get nodes by category/branch
  Iterable<SkillNode> nodesInBranch(SkillCategory category) {
    return nodes.where((n) => n.category == category);
  }

  /// Check if a node can be unlocked (all prerequisites met)
  bool canUnlock(String nodeId) {
    final node = getNodeById(nodeId);
    if (node == null || node.unlocked) return false;

    // Check if all prerequisite nodes are unlocked
    final prerequisites = edges
        .where((e) => e.toId == nodeId)
        .map((e) => getNodeById(e.fromId))
        .where((n) => n != null);

    return prerequisites.every((prereq) => prereq!.unlocked);
  }

  /// Get list of prerequisite node IDs for a given node
  List<String> getPrerequisites(String nodeId) {
    return edges
        .where((e) => e.toId == nodeId)
        .map((e) => e.fromId)
        .toList();
  }

  /// Get list of dependent node IDs for a given node
  List<String> getDependents(String nodeId) {
    return edges
        .where((e) => e.fromId == nodeId)
        .map((e) => e.toId)
        .toList();
  }

  /// Get all available nodes (unlocked prerequisites)
  Iterable<SkillNode> get availableNodes {
    return nodes.where((node) => !node.unlocked && canUnlock(node.id));
  }

  /// Get all unlocked nodes
  Iterable<SkillNode> get unlockedNodes {
    return nodes.where((node) => node.unlocked);
  }

  SkillTreeGraph copy() {
    return SkillTreeGraph(
      nodes: nodes.map((n) => n.copyWith()).toList(),
      edges: List.from(edges),
      groups: groups,
    );
  }

  /// Factory constructor for loading from grouped JSON structure
  factory SkillTreeGraph.fromGroupedJson(Map<String, dynamic> json) {
    final nodes = <SkillNode>[];
    final edges = <SkillEdge>[];
    final groups = <String, SkillGroup>{};

    // Extract nodes from all groups
    final skillTreeGroups = json['skill_tree_groups'] as Map<String, dynamic>;

    for (final groupEntry in skillTreeGroups.entries) {
      final groupData = groupEntry.value as Map<String, dynamic>;
      final branches = groupData['branches'] as Map<String, dynamic>;

      // Create group
      groups[groupEntry.key] = SkillGroup(
        id: groupEntry.key,
        title: groupData['title'],
        description: groupData['description'],
        color: groupData['color'],
        branchIds: branches.keys.toList(),
      );

      // Extract nodes from branches
      for (final branchEntry in branches.entries) {
        final branchNodes = branchEntry.value['nodes'] as List;
        for (final nodeData in branchNodes) {
          nodes.add(SkillNode.fromJson(nodeData));
        }
      }
    }

    // Extract edges
    final edgesData = json['edges'] as List? ?? [];
    for (final edgeData in edgesData) {
      edges.add(SkillEdge.fromJson(edgeData as Map<String, dynamic>));
    }

    return SkillTreeGraph(nodes: nodes, edges: edges, groups: groups);
  }

  /// Factory constructor for loading from simple JSON structure
  factory SkillTreeGraph.fromJson(Map<String, dynamic> json) {
    final nodes = <SkillNode>[];
    final edges = <SkillEdge>[];

    // Extract nodes
    final nodesData = json['nodes'] as List? ?? [];
    for (final nodeData in nodesData) {
      nodes.add(SkillNode.fromJson(nodeData as Map<String, dynamic>));
    }

    // Extract edges
    final edgesData = json['edges'] as List? ?? [];
    for (final edgeData in edgesData) {
      edges.add(SkillEdge.fromJson(edgeData as Map<String, dynamic>));
    }

    return SkillTreeGraph(nodes: nodes, edges: edges);
  }
}

/// Represents a skill group containing multiple branches
class SkillGroup {
  final String id;
  final String title;
  final String description;
  final String color;
  final List<String> branchIds;

  const SkillGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.branchIds,
  });

  factory SkillGroup.fromJson(Map<String, dynamic> json) {
    final branches = json['branches'] as Map<String, dynamic>? ?? {};
    return SkillGroup(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '#FFFFFF',
      branchIds: branches.keys.toList(),
    );
  }
}

extension SkillTreeGraphBranch on SkillTreeGraph {
  SkillTreeGraph subgraphForBranch(String branchId) {
    final ids = nodes.where((n) => n.branchId == branchId).map((n) => n.id).toSet();
    return SkillTreeGraph(
      nodes: nodes.where((n) => ids.contains(n.id)).toList(),
      edges: edges.where((e) => ids.contains(e.fromId) && ids.contains(e.toId)).toList(),
    );
  }
  int indegree(String id) => edges.where((e) => e.toId == id).length;
  Iterable<String> neighbors(String id) => edges.where((e) => e.fromId == id).map((e) => e.toId);
}

