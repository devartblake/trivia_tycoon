import 'dart:convert';
import 'package:synaptix/core/services/asset_resolver.dart';
import '../../game/models/store_item_model.dart';

class StoreItemLoader {
  static Future<List<StoreItemModel>> loadFromAssets() async {
    final jsonString =
        await AssetResolver.instance.loadString('store-catalog/items');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final List<dynamic> itemsJson = jsonMap['items'];
    return itemsJson.map((e) => StoreItemModel.fromJson(e)).toList();
  }
}
