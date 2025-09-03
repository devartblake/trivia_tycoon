import 'package:flutter/foundation.dart';

enum SkillCategory { Scholar, Strategist, XP }

@immutable
class SkillNode {
  final String id;
  final String title;
  final String description;
  final int tier; // 0..n (row)
  final bool unlocked;
  final int cost; // XP or tokens
  final Map<String, num> effects; // e.g. {"timeBonusSec": 5, "sportsScoreBoost": 0.1}
  final SkillCategory category;

  const SkillNode({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.category,
    this.unlocked = false,
    this.cost = 1,
    this.effects = const {},
  });

  SkillNode copyWith({bool? unlocked}) =>
      SkillNode(
        id: id, title: title,
        description: description,
        tier: tier,
        category: category,
        unlocked: unlocked ?? this.unlocked,
        cost: cost,
        effects: effects,
      );
}

@immutable
class SkillEdge {
  final String fromId;
  final String toId;
  const SkillEdge({required this.fromId, required this.toId});
}

@immutable
class SkillTreeGraph {
  final List<SkillNode> nodes;
  final List<SkillEdge> edges;
  const SkillTreeGraph({required this.nodes, required this.edges});

  Map<String, SkillNode> get byId => {for (final n in nodes) n.id: n};
  Iterable<SkillNode> tier(int t) => nodes.where((n) => n.tier == t);
  int get maxTier => nodes.fold<int>(0, (m, n) => n.tier > m ? n.tier : m);
}
