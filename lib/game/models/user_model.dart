class UserModel {
  final String id;
  final String email;
  final List<String> roles;
  final bool isPremium;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.roles,
    required this.isPremium,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
    roles: List<String>.from(json['roles'] ?? []),
    isPremium: json['isPremium'] ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'roles': roles,
    'isPremium': isPremium,
    'createdAt': createdAt.toIso8601String(),
  };

  UserModel copyWith({
    String? id,
    String? email,
    List<String>? roles,
    bool? isPremium,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
