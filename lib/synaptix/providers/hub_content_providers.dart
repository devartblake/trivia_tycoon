import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

class FeaturedMatchData {
  final String title;
  final String difficulty;
  final String category;

  const FeaturedMatchData({
    required this.title,
    required this.difficulty,
    required this.category,
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

  return FeaturedMatchData(
    title: title,
    difficulty: 'Medium',
    category: category,
  );
});
