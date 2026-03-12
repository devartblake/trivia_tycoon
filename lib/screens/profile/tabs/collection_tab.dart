import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/collection_items_providers.dart';
import '../../../game/models/collection_item.dart';

class CollectionTab extends ConsumerStatefulWidget {
  const CollectionTab({super.key});

  @override
  ConsumerState<CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends ConsumerState<CollectionTab> {
  String _selectedFilter = 'all'; // all, unlocked, locked
  String? _selectedCategory;
  String? _selectedRarity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionAsync = ref.watch(collectionCompletionProvider);
    final totalCountAsync = ref.watch(totalCollectionCountProvider);
    final unlockedCountAsync = ref.watch(unlockedCollectionCountProvider);

    // Get filtered items based on current filter
    AsyncValue<List<CollectionItem>> itemsAsync;

    if (_selectedCategory != null) {
      itemsAsync = ref.watch(collectionItemsByCategoryProvider(_selectedCategory!));
    } else if (_selectedRarity != null) {
      itemsAsync = ref.watch(collectionItemsByRarityProvider(_selectedRarity!));
    } else if (_selectedFilter == 'unlocked') {
      itemsAsync = ref.watch(unlockedCollectionItemsProvider);
    } else if (_selectedFilter == 'locked') {
      itemsAsync = ref.watch(lockedCollectionItemsProvider);
    } else {
      itemsAsync = ref.watch(allCollectionItemsProvider);
    }

    return Scaffold(
      body: Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Collection',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Row(
                      children: [
                        totalCountAsync.when(
                          data: (total) => unlockedCountAsync.when(
                            data: (unlocked) => Text(
                              '$unlocked / $total',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                completionAsync.when(
                  data: (percentage) => Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}% Complete',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', theme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unlocked', 'unlocked', theme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Locked', 'locked', theme),
                  const SizedBox(width: 16),
                  // Category filters
                  _buildCategoryChip('Arts & Culture', theme),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Science & Discovery', theme),
                  const SizedBox(width: 8),
                  _buildCategoryChip('History & Literature', theme),
                ],
              ),
            ),
          ),

          // Collection Grid
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Play trivia to unlock collection items!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return CollectionItemCard(item: items[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading collection',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = _selectedFilter == value && _selectedCategory == null && _selectedRarity == null;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _selectedCategory = null;
          _selectedRarity = null;
        });
      },
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildCategoryChip(String category, ThemeData theme) {
    final isSelected = _selectedCategory == category;

    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
          _selectedRarity = null;
          _selectedFilter = 'all';
        });
      },
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.secondaryContainer,
      checkmarkColor: theme.colorScheme.onSecondaryContainer,
    );
  }
}

class CollectionItemCard extends ConsumerWidget {
  final CollectionItem item;

  const CollectionItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imagePathAsync = ref.watch(itemImagePathProvider(item.id));
    final rarityColor = Color(
      int.parse(item.rarityColor.substring(1), radix: 16) + 0xFF000000,
    );

    return GestureDetector(
      onTap: () => _showItemDetails(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: item.isUnlocked
              ? Border.all(color: rarityColor, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: theme.colorScheme.surfaceContainerHigh,
                      child: imagePathAsync.when(
                        data: (imagePath) {
                          if (imagePath != null && item.isUnlocked) {
                            return Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder(theme, rarityColor);
                              },
                            );
                          } else {
                            return _buildLockedPlaceholder(theme);
                          }
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (_, __) => _buildPlaceholder(theme, rarityColor),
                      ),
                    ),
                  ),

                  // Locked overlay
                  if (!item.isUnlocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                        ),
                        child: const Icon(
                          Icons.lock,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                    ),

                  // Rarity badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.rarity.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Item Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.pointValue} pts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, Color rarityColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rarityColor.withValues(alpha: 0.3),
            rarityColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildLockedPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Icon(
        Icons.help_outline,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  void _showItemDetails(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rarityColor = Color(
      int.parse(item.rarityColor.substring(1), radix: 16) + 0xFF000000,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Item details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rarity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.rarity.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Item name
                    Text(
                      item.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Category and points
                    Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.category,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.stars,
                          size: 20,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.pointValue} pts',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      item.description,
                      style: theme.textTheme.bodyMedium,
                    ),

                    if (!item.isUnlocked) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Complete trivia challenges in ${item.category} to unlock this item!',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (item.unlockedAt != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Unlocked on ${_formatDate(item.unlockedAt!)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}