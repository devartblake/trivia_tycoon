import 'package:flutter/material.dart';
import '../models/search.dart';
import '../providers/skill_search_provider.dart';

class SearchService {
  final List<SearchProvider> _providers;

  SearchService(this._providers);

  Future<List<SearchResult>> search(String query, SearchFilter filter) async {
    if (query.trim().isEmpty) return [];

    final allResults = <SearchResult>[];

    // Search across all enabled providers
    for (final provider in _providers.where((p) => p.isEnabled)) {
      try {
        final results = await provider.search(query.trim(), filter);
        allResults.addAll(results);
      } catch (e) {
        debugPrint('Search error in ${provider.category}: $e');
      }
    }

    // Sort by relevance and limit results
    allResults.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return allResults.take(50).toList(); // Limit to top 50 results
  }

  Future<Map<SearchCategory, List<SearchResult>>> searchByCategory(
      String query,
      SearchFilter filter
      ) async {
    final results = await search(query, filter);
    final grouped = <SearchCategory, List<SearchResult>>{};

    for (final result in results) {
      grouped.putIfAbsent(result.category, () => []).add(result);
    }

    return grouped;
  }
}