import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/models/search.dart';
import '../game/providers/search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final SearchCategory? initialCategory;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');

    if (widget.initialQuery != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchQueryProvider.notifier).state = widget.initialQuery!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final searchResultsByCategory = ref.watch(searchResultsByCategoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1021),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15183A),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search skills, settings, players...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
          ),
          onChanged: (query) {
            ref.read(searchQueryProvider.notifier).state = query;
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilterSection(),
          Expanded(
            child: searchResults.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Search error: $error', style: const TextStyle(color: Colors.white)),
              ),
              data: (results) => results.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsList(results),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filter = ref.watch(searchFilterProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF15183A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SearchCategory.values.map((category) {
              final isSelected = filter.categories.contains(category);
              return FilterChip(
                label: Text(category.name),
                selected: isSelected,
                onSelected: (selected) {
                  final newCategories = Set<SearchCategory>.from(filter.categories);
                  if (selected) {
                    newCategories.add(category);
                  } else {
                    newCategories.remove(category);
                  }
                  ref.read(searchFilterProvider.notifier).state =
                      filter.copyWith(categories: newCategories);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final query = ref.watch(searchQueryProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'Start typing to search' : 'No results found',
            style: const TextStyle(color: Colors.white60, fontSize: 18),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check filters',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsList(List<SearchResult> results) {
    // Group results by category for better organization
    final grouped = <SearchCategory, List<SearchResult>>{};
    for (final result in results) {
      grouped.putIfAbsent(result.category, () => []).add(result);
    }

    return ListView.builder(
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final category = grouped.keys.elementAt(index);
        final categoryResults = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                category.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            ...categoryResults.map((result) => _buildResultCard(result)),
            const Divider(color: Colors.white10),
          ],
        );
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: result.color?.withOpacity(0.2),
        child: Icon(result.icon, color: result.color ?? Colors.white),
      ),
      title: Text(result.title, style: const TextStyle(color: Colors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.description, style: const TextStyle(color: Colors.white70)),
          if (result.subtitle != null)
            Text(result.subtitle!, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
      trailing: result.metadata?['unlocked'] == true
          ? const Icon(Icons.check_circle, color: Colors.green)
          : result.metadata?['cost'] != null
          ? Text('${result.metadata!['cost']}', style: const TextStyle(color: Colors.orange))
          : null,
      onTap: () {
        if (result.navigationRoute != null) {
          context.push(result.navigationRoute!);
        }
      },
    );
  }
}