import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/ui_components/power_ups/power_up_inventory_widget.dart';
import '../../core/services/settings/app_settings.dart';
import 'widgets/currency_display_bar.dart';
import 'widgets/store_category_tab.dart';
import 'widgets/store_item_card.dart';
// import '../../core/utils/sample_store_data.dart'; // For sample items

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(storeItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛒 Game Store"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedCategory = 'All';
              });
            },
          )
        ],
      ),
      body: asyncItems.when(
        data: (items) {
      final categories = ['All', ...{for (var item in items) item.category}];
      final storeItems = items.where((item) =>
      _selectedCategory == 'All' || item.category == _selectedCategory).toList();

      return Column(
        children: [
          const SizedBox(height: 12),
          const CurrencyDisplayBar(),
          const SizedBox(height: 12),
          const PowerUpInventoryWidget(),
          const SizedBox(height: 12),
          StoreCategoryTab(
            categories: categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (value) {
              setState(() => _selectedCategory = value);
            },
          ),

          const SizedBox(height: 12),

          /// 🛍️ Store Items Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: storeItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final item = storeItems[index];
                return StoreItemCard(
                  item: item,
                  name: item.name,
                  description: item.description,
                  iconPath: item.iconPath,
                  price: item.price.toString(),
                  onBuy: () async {
                    final coins = ref.read(coinBalanceProvider);
                    if (coins >= item.price) {
                      ref.read(coinNotifierProvider).deduct(item.price);
                      await AppSettings.addPurchasedItem(item.id);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Purchased ${item.name}")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Not enough coins!")),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load store items: $err')),
      ),
    );
  }
}
