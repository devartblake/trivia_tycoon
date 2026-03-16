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
                ?.map((e) =>
                    SkillNodeDto.fromJson(e as Map<String, dynamic>))
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
