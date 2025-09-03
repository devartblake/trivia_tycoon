class GameBadge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final bool isUnlocked;

  GameBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    this.isUnlocked = false,
  });

  factory GameBadge.fromJson(Map<String, dynamic> json) => GameBadge(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    iconPath: json['iconPath'],
    isUnlocked: json['isUnlocked'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconPath': iconPath,
    'isUnlocked': isUnlocked,
  };
}
