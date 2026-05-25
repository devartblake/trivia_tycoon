import 'dart:convert';
import 'package:trivia_tycoon/core/services/asset_resolver.dart';
import '../../game/models/store_item_model.dart';
import '../models/power_up.dart';

class StoreDataService {
  static Future<List<StoreItemModel>> loadStoreItems() async {
    final String jsonString =
        await AssetResolver.instance.loadString('store-catalog/items');
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((item) => StoreItemModel.fromJson(item)).toList();
  }

  static Future<List<PowerUp>> loadPowerUps() async {
    final json =
        await AssetResolver.instance.loadString('store-catalog/power-ups');
    final List<dynamic> data = jsonDecode(json);
    return data.map((item) => PowerUp.fromJson(item)).toList();
  }

// Extendable for other models like badges, themes, avatars, etc.
}
