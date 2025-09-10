import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/skill_search_provider.dart';
import 'package:trivia_tycoon/game/providers/skill_tree_nav_providers.dart';
import '../models/search.dart';
import '../services/search_service.dart';

final searchServiceProvider = Provider<SearchService>((ref) {
  final skillRepo = ref.watch(skillTreeNavRepoProvider);

  return SearchService([
    SkillSearchProvider(skillRepo),
    NavigationSearchProvider(),
    // Add more providers as needed:
    // QuestionSearchProvider(),
    // PlayerSearchProvider(),
    // AchievementSearchProvider(),
  ]);
});

final searchFilterProvider = StateProvider<SearchFilter>((ref) => SearchFilter());

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final service = ref.watch(searchServiceProvider);
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(searchFilterProvider);

  if (query.trim().isEmpty) return [];

  return service.search(query, filter);
});

final searchResultsByCategoryProvider = FutureProvider<Map<SearchCategory, List<SearchResult>>>((ref) async {
  final service = ref.watch(searchServiceProvider);
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(searchFilterProvider);

  if (query.trim().isEmpty) return {};

  return service.searchByCategory(query, filter);
});