import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/search.dart';
import 'package:trivia_tycoon/game/providers/skill_search_provider.dart';
import 'package:trivia_tycoon/game/services/search_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _MockProvider implements SearchProvider {
  final SearchCategory _category;
  final bool _enabled;
  final List<SearchResult> _results;
  final bool _shouldThrow;

  _MockProvider({
    SearchCategory category = SearchCategory.skills,
    bool enabled = true,
    List<SearchResult> results = const [],
    bool shouldThrow = false,
  })  : _category = category,
        _enabled = enabled,
        _results = results,
        _shouldThrow = shouldThrow;

  @override
  SearchCategory get category => _category;

  @override
  bool get isEnabled => _enabled;

  @override
  Future<List<SearchResult>> search(String query, SearchFilter filter) async {
    if (_shouldThrow) throw Exception('provider error');
    return _results;
  }
}

SearchResult _result({
  String id = 'r1',
  String title = 'Result',
  int relevanceScore = 50,
  SearchCategory category = SearchCategory.skills,
}) =>
    SearchResult(
      id: id,
      title: title,
      description: '',
      type: SearchResultType.skill,
      category: category,
      relevanceScore: relevanceScore,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Empty / whitespace queries
  // -------------------------------------------------------------------------

  group('SearchService — empty query', () {
    test('returns [] immediately for empty string', () async {
      final svc = SearchService([_MockProvider(results: [_result()])]);
      final results = await svc.search('', SearchFilter());
      expect(results, isEmpty);
    });

    test('returns [] for whitespace-only string', () async {
      final svc = SearchService([_MockProvider(results: [_result()])]);
      final results = await svc.search('   ', SearchFilter());
      expect(results, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Provider enablement
  // -------------------------------------------------------------------------

  group('SearchService — provider enablement', () {
    test('disabled provider is skipped', () async {
      final disabled = _MockProvider(
        enabled: false,
        results: [_result(id: 'hidden')],
      );
      final svc = SearchService([disabled]);
      final results = await svc.search('query', SearchFilter());
      expect(results.any((r) => r.id == 'hidden'), isFalse);
    });

    test('enabled provider is included', () async {
      final enabled = _MockProvider(results: [_result(id: 'visible')]);
      final svc = SearchService([enabled]);
      final results = await svc.search('query', SearchFilter());
      expect(results.any((r) => r.id == 'visible'), isTrue);
    });

    test('results from multiple enabled providers are merged', () async {
      final p1 = _MockProvider(results: [_result(id: 'a')]);
      final p2 = _MockProvider(results: [_result(id: 'b')]);
      final svc = SearchService([p1, p2]);
      final results = await svc.search('query', SearchFilter());
      expect(results.map((r) => r.id).toSet(), {'a', 'b'});
    });
  });

  // -------------------------------------------------------------------------
  // Sorting by relevance score
  // -------------------------------------------------------------------------

  group('SearchService — sorting', () {
    test('results sorted descending by relevanceScore', () async {
      final provider = _MockProvider(results: [
        _result(id: 'low', relevanceScore: 20),
        _result(id: 'high', relevanceScore: 90),
        _result(id: 'mid', relevanceScore: 50),
      ]);
      final svc = SearchService([provider]);
      final results = await svc.search('x', SearchFilter());
      expect(results.map((r) => r.id).toList(), ['high', 'mid', 'low']);
    });

    test('equal scores return all matching results', () async {
      final provider = _MockProvider(results: [
        _result(id: 'a', relevanceScore: 50),
        _result(id: 'b', relevanceScore: 50),
      ]);
      final svc = SearchService([provider]);
      final results = await svc.search('x', SearchFilter());
      expect(results.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // Result cap at 50
  // -------------------------------------------------------------------------

  group('SearchService — result cap', () {
    test('caps at 50 results total', () async {
      final manyResults = List.generate(
        80,
        (i) => _result(id: 'r$i', relevanceScore: i),
      );
      final provider = _MockProvider(results: manyResults);
      final svc = SearchService([provider]);
      final results = await svc.search('x', SearchFilter());
      expect(results.length, 50);
    });

    test('returns top-50 by relevance score when over 50', () async {
      final manyResults = List.generate(
        60,
        (i) => _result(id: 'r$i', relevanceScore: i),
      );
      final provider = _MockProvider(results: manyResults);
      final svc = SearchService([provider]);
      final results = await svc.search('x', SearchFilter());
      // Top 50 should have highest scores (indices 10–59 → scores 10–59)
      expect(results.first.relevanceScore, 59);
      expect(results.last.relevanceScore, 10);
    });
  });

  // -------------------------------------------------------------------------
  // Error handling
  // -------------------------------------------------------------------------

  group('SearchService — error handling', () {
    test('throwing provider is swallowed; other providers still contribute', () async {
      final throwing = _MockProvider(category: SearchCategory.players, shouldThrow: true);
      final good = _MockProvider(results: [_result(id: 'ok')]);
      final svc = SearchService([throwing, good]);
      final results = await svc.search('query', SearchFilter());
      expect(results.any((r) => r.id == 'ok'), isTrue);
    });

    test('all providers throwing returns empty list', () async {
      final svc = SearchService([
        _MockProvider(shouldThrow: true),
        _MockProvider(category: SearchCategory.players, shouldThrow: true),
      ]);
      final results = await svc.search('query', SearchFilter());
      expect(results, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // searchByCategory
  // -------------------------------------------------------------------------

  group('SearchService.searchByCategory', () {
    test('groups results by category', () async {
      final provider = _MockProvider(results: [
        _result(id: 'sk', category: SearchCategory.skills),
        _result(id: 'pl', category: SearchCategory.players),
      ]);
      final svc = SearchService([provider]);
      final grouped = await svc.searchByCategory('x', SearchFilter());
      expect(grouped[SearchCategory.skills]?.length, 1);
      expect(grouped[SearchCategory.players]?.length, 1);
      expect(grouped[SearchCategory.skills]?.first.id, 'sk');
    });

    test('returns empty map for empty query', () async {
      final svc = SearchService([_MockProvider(results: [_result()])]);
      final grouped = await svc.searchByCategory('', SearchFilter());
      expect(grouped, isEmpty);
    });
  });
}
