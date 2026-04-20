import 'package:flutter/material.dart';

class FavoriteCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int questionCount;
  final double progress;
  final bool isFavorite;

  FavoriteCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.questionCount,
    required this.progress,
    this.isFavorite = false,
  });

  FavoriteCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    int? questionCount,
    double? progress,
    bool? isFavorite,
  }) {
    return FavoriteCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      questionCount: questionCount ?? this.questionCount,
      progress: progress ?? this.progress,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
