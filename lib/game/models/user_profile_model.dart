class UserModel {
  final String userId;
  final String email;
  final bool isPremium;
  final List<String> roles;

  UserModel({
    required this.userId,
    required this.email,
    this.isPremium = false,
    this.roles = const ['player'],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      email: json['email'],
      isPremium: json['isPremium'] ?? false,
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'isPremium': isPremium,
    'roles': roles,
  };

  UserModel copyWith({
    String? userId,
    String? email,
    bool? isPremium,
    List<String>? roles,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      roles: roles ?? List.from(this.roles),
    );
  }
}
