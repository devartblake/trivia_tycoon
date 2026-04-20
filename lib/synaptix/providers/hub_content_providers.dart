import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

class FeaturedMatchData {
  final String title;
  final String difficulty;
  final String category;
  final IconData icon;
  final Color iconColor;
  final bool isFallback;
  final String? fallbackReason;

  const FeaturedMatchData({
    required this.title,
    required this.difficulty,
    required this.category,
    required this.icon,
    required this.iconColor,
    this.isFallback = false,
    this.fallbackReason,
  });
}

/// Data-driven featured match provider for Synaptix Hub.
final featuredMatchProvider = Provider<FeaturedMatchData>((ref) {
  FeaturedMatchData fallback({String? reason}) => FeaturedMatchData(
        title: 'Global Science Showdown',
        difficulty: 'Medium',
        category: 'Science',
        icon: Icons.science_rounded,
        iconColor: Colors.purpleAccent,
        isFallback: true,
        fallbackReason: reason,
      );

  try {
    final profileService = ref.watch(playerProfileServiceProvider);
    final profile = profileService.getProfile();
    final categories =
        (profile['preferredCategories'] as List<dynamic>?)?.cast<String>() ??
            const <String>[];

    final selectedCategory = categories
        .map((c) => c.trim())
        .firstWhere((c) => c.isNotEmpty, orElse: () => '');
    if (selectedCategory.isEmpty) {
      return fallback(reason: 'no_preferred_categories');
    }

    final category = selectedCategory;
    final title = 'Global $category Showdown';
    final lower = category.toLowerCase();

    final (IconData, Color) visual = switch (lower) {
      final c when c.contains('science') => (
          Icons.science_rounded,
          Colors.purpleAccent
        ),
      final c when c.contains('history') => (
          Icons.history_edu_rounded,
          Colors.amberAccent
        ),
      final c when c.contains('geography') => (
          Icons.public_rounded,
          Colors.lightBlueAccent
        ),
      final c when c.contains('math') => (
          Icons.calculate_rounded,
          Colors.greenAccent
        ),
      _ => (Icons.public_rounded, Colors.purpleAccent),
    };

    return FeaturedMatchData(
      title: title,
      difficulty: 'Medium',
      category: category,
      icon: visual.$1,
      iconColor: visual.$2,
    );
  } catch (_) {
    return fallback(reason: 'provider_exception');
  }
});
