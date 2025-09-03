import 'dart:convert';
import 'package:flutter/services.dart';
import '../../game/models/store_item_model.dart';
import '../models/power_up.dart';

class StoreDataService {
  static Future<List<StoreItemModel>> loadStoreItems() async {
    final String jsonString = await rootBundle.loadString('assets/data/store_items.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    return jsonData.map((item) => StoreItemModel.fromJson(item)).toList();
  }

  static Future<List<PowerUp>> loadPowerUps() async {
    final json = await rootBundle.loadString('assets/data/power_ups.json');
    final List<dynamic> data = jsonDecode(json);
    return data.map((item) => PowerUp.fromJson(item)).toList();
  }

// Extendable for other models like badges, themes, avatars, etc.
}