/// Mirrors backend SkillCostDto ({currency, amount}).
class SkillCostDto {
  final String currency; // "Coins" | "Diamonds"
  final int amount;

  const SkillCostDto({required this.currency, required this.amount});

  factory SkillCostDto.fromJson(Map<String, dynamic> j) => SkillCostDto(
        currency: j['currency'] as String? ?? 'Coins',
        amount: j['amount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'currency': currency, 'amount': amount};
}

/// Mirrors backend SkillNodeDto from GET /skills/tree (catalog definition).
class SkillCatalogNodeDto {
  final String key;
  final String branch; // "Knowledge" | "Strategy" | "Powerups"
  final int tier;
  final String title;
  final String description;
  final List<String> prereqKeys;
  final List<SkillCostDto> costs;
  final Map<String, double> effects;

  const SkillCatalogNodeDto({
    required this.key,
    required this.branch,
    required this.tier,
    required this.title,
    required this.description,
    required this.prereqKeys,
    required this.costs,
    required this.effects,
  });

  /// Coin cost of the node (0 when the node has no coin cost).
  int get coinCost => costs
      .where((c) => c.currency.toLowerCase() == 'coins')
      .fold(0, (sum, c) => sum + c.amount);

  factory SkillCatalogNodeDto.fromJson(Map<String, dynamic> j) =>
      SkillCatalogNodeDto(
        key: j['key'] as String,
        branch: j['branch'] as String? ?? 'Knowledge',
        tier: j['tier'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        prereqKeys: (j['prereqKeys'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        costs: (j['costs'] as List<dynamic>?)
                ?.map((e) => SkillCostDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        effects: (j['effects'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            {},
      );
}

/// Mirrors backend SkillTreeCatalogDto (GET /skills/tree).
class SkillCatalogDto {
  final List<SkillCatalogNodeDto> nodes;

  const SkillCatalogDto({required this.nodes});

  factory SkillCatalogDto.fromJson(Map<String, dynamic> j) => SkillCatalogDto(
        nodes: (j['nodes'] as List<dynamic>?)
                ?.map((e) =>
                    SkillCatalogNodeDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// Mirrors backend PlayerSkillStateDto (GET /skills/state/{playerId}).
class PlayerSkillStateDto {
  final String playerId;
  final List<String> unlockedKeys;

  const PlayerSkillStateDto({
    required this.playerId,
    required this.unlockedKeys,
  });

  factory PlayerSkillStateDto.fromJson(Map<String, dynamic> j) =>
      PlayerSkillStateDto(
        playerId: j['playerId'] as String,
        unlockedKeys: (j['unlockedKeys'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}

/// Legacy client-side node shape, composed from the catalog + player state by
/// [SynaptixApiClient.getSkillTree] (the backend has no endpoint returning
/// this shape directly).
class SkillNodeDto {
  final String id;
  final String name;
  final String description;
  final bool unlocked;
  final int cost;
  final List<String> requires;

  const SkillNodeDto({
    required this.id,
    required this.name,
    required this.description,
    required this.unlocked,
    required this.cost,
    required this.requires,
  });

  factory SkillNodeDto.fromJson(Map<String, dynamic> j) => SkillNodeDto(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String? ?? '',
        unlocked: j['unlocked'] as bool? ?? false,
        cost: j['cost'] as int? ?? 0,
        requires: (j['requires'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'unlocked': unlocked,
        'cost': cost,
        'requires': requires,
      };
}

class SkillTreeDto {
  final String playerId;
  final List<SkillNodeDto> nodes;
  final int availablePoints;

  const SkillTreeDto({
    required this.playerId,
    required this.nodes,
    required this.availablePoints,
  });

  factory SkillTreeDto.fromJson(Map<String, dynamic> j) => SkillTreeDto(
        playerId: j['playerId'] as String,
        nodes: (j['nodes'] as List<dynamic>?)
                ?.map((e) => SkillNodeDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        availablePoints: j['availablePoints'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'availablePoints': availablePoints,
      };
}
