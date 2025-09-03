import 'dart:convert';
import 'package:flutter/services.dart';
import '../../game/models/store_item_model.dart';

class StoreItemLoader {
  static Future<List<StoreItemModel>> loadFromAssets() async {
    final jsonString = await rootBundle.loadString('assets/data/store_items.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final List<dynamic> itemsJson = jsonMap['items'];
    return itemsJson.map((e) => StoreItemModel.fromJson(e)).toList();
  }
}
