import 'package:flutter/material.dart';

class StickerPack {
  final String id;
  final String name;
  final String description;
  final List<String> stickers;
  final int price;
  final bool isPremium;
  final bool isOwned;
  final String category;

  const StickerPack({
    required this.id,
    required this.name,
    required this.description,
    required this.stickers,
    required this.price,
    this.isPremium = false,
    this.isOwned = false,
    required this.category,
  });
}

class StickerPacksScreen extends StatefulWidget {
  final String currentUserId;

  const StickerPacksScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<StickerPacksScreen> createState() => _StickerPacksScreenState();
}

class _StickerPacksScreenState extends State<StickerPacksScreen> {
  String _selectedCategory = 'All';

  final List<StickerPack> _packs = [
    const StickerPack(
      id: 'emoji_basics',
      name: 'Emoji Basics',
      description: 'Essential emoji expressions',
      stickers: ['😀', '😂', '🥰', '😎', '🤔', '👍', '❤️', '🎉'],
      price: 0,
      isOwned: true,
      category: 'General',
    ),
    const StickerPack(
      id: 'gaming',
      name: 'Gaming Pack',
      description: 'For true gamers',
      stickers: ['🎮', '🕹️', '🏆', '⭐', '💎', '🚀', '⚡', '🔥'],
      price: 150,
      category: 'Gaming',
    ),
    const StickerPack(
      id: 'reactions',
      name: 'Reactions',
      description: 'Express yourself',
      stickers: ['😱', '🤯', '😍', '🤩', '😤', '💪', '👏', '🙌'],
      price: 200,
      category: 'Reactions',
    ),
    const StickerPack(
      id: 'animals',
      name: 'Cute Animals',
      description: 'Adorable creatures',
      stickers: ['🐶', '🐱', '🐼', '🦊', '🐨', '🐰', '🦁', '🐯'],
      price: 250,
      category: 'Fun',
    ),
    const StickerPack(
      id: 'food',
      name: 'Foodie',
      description: 'Delicious treats',
      stickers: ['🍕', '🍔', '🍟', '🌮', '🍣', '🍰', '🍦', '☕'],
      price: 200,
      category: 'Fun',
    ),
    const StickerPack(
      id: 'premium_animated',
      name: 'Animated Premium',
      description: 'Exclusive animated stickers',
      stickers: ['✨', '💫', '⚡', '🌟', '💥', '🎊', '🎆', '🌈'],
      price: 500,
      isPremium: true,
      category: 'Premium',
    ),
  ];

  List<String> get _categories {
    final cats = _packs.map((p) => p.category).toSet().toList();
    cats.insert(0, 'All');
    return cats;
  }

  List<StickerPack> get _filteredPacks {
    if (_selectedCategory == 'All') return _packs;
    return _packs.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticker Packs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            onPressed: _showOwnedPacks,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredPacks.length,
              itemBuilder: (context, index) {
                return _buildPackCard(_filteredPacks[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackCard(StickerPack pack) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showPackPreview(pack),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        pack.stickers.first,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pack.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (pack.isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.star, size: 12),
                                    SizedBox(width: 2),
                                    Text(
                                      'PRO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Text(
                          pack.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pack.stickers.length} stickers',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pack.stickers.take(8).map((sticker) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(sticker, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!pack.isOwned)
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, size: 20, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${pack.price} Coins',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Owned',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  FilledButton(
                    onPressed: () => _showPackPreview(pack),
                    child: Text(pack.isOwned ? 'Use' : 'Preview'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPackPreview(StickerPack pack) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          pack.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: pack.stickers.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          pack.stickers[index],
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (!pack.isOwned)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _purchasePack(pack),
                    icon: const Icon(Icons.shopping_cart),
                    label: Text('Purchase for ${pack.price} Coins'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _purchasePack(StickerPack pack) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${pack.name}'),
        content: Text('Buy this sticker pack for ${pack.price} coins?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${pack.name} purchased!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  void _showOwnedPacks() {
    final ownedPacks = _packs.where((p) => p.isOwned).toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Sticker Packs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: ownedPacks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Text(
                      ownedPacks[index].stickers.first,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(ownedPacks[index].name),
                    subtitle: Text('${ownedPacks[index].stickers.length} stickers'),
                    onTap: () {
                      Navigator.pop(context);
                      _showPackPreview(ownedPacks[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
