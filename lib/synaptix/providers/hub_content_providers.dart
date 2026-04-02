import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

class FeaturedMatchData {
  final String title;
  final String difficulty;
  final String category;
  final IconData icon;
  final Color iconColor;

  const FeaturedMatchData({
    required this.title,
    required this.difficulty,
    required this.category,
    required this.icon,
    required this.iconColor,
  });
}

/// Data-driven featured match provider for Synaptix Hub.
final featuredMatchProvider = Provider<FeaturedMatchData>((ref) {
  final profileService = ref.watch(playerProfileServiceProvider);
  final profile = profileService.getProfile();
  final categories =
      (profile['preferredCategories'] as List<dynamic>?)?.cast<String>() ??
          const <String>[];

  final category = categories.isNotEmpty ? categories.first : 'Science';
  final title = 'Global $category Showdown';
  final lower = category.toLowerCase();

  final (IconData, Color) visual = switch (lower) {
    final c when c.contains('science') => (Icons.science_rounded, Colors.purpleAccent),
    final c when c.contains('history') => (Icons.history_edu_rounded, Colors.amberAccent),
    final c when c.contains('geography') => (Icons.public_rounded, Colors.lightBlueAccent),
    final c when c.contains('math') => (Icons.calculate_rounded, Colors.greenAccent),
    _ => (Icons.public_rounded, Colors.purpleAccent),
  };

  return FeaturedMatchData(
    title: title,
    difficulty: 'Medium',
    category: category,
    icon: visual.$1,
    iconColor: visual.$2,
  );
});
