import '../../game/models/store_item_model.dart';

class SampleStoreData {
  final List<StoreItemModel> sampleStoreItems = [
    StoreItemModel(
      id: 'avatar_fox',
      name: 'Fox Avatar',
      description: 'A cool fox-themed avatar!',
      iconPath: 'assets/images/store/avatars/fox.png',
      price: 200,
      currency: 'coins',
      category: 'avatar',
    ),
    StoreItemModel(
      id: 'theme_dark',
      name: 'Dark Mode Theme',
      description: 'A sleek dark interface for nighttime play.',
      iconPath: 'assets/images/store/themes/dark.png',
      price: 350,
      currency: 'diamonds',
      category: 'theme',
    ),
    StoreItemModel(
      id: 'power_hint',
      name: 'Hint Power-Up',
      description: 'Reveal one correct answer.',
      iconPath: 'assets/images/store/power-ups/hint.png',
      price: 100,
      currency: 'coins',
      category: 'power-up',
    ),
  ];
}
