import 'dart:convert';
import 'package:trivia_tycoon/core/services/asset_resolver.dart';
import '../../../game/models/power_up.dart';

class PowerUpService {
  static Future<List<PowerUp>> loadPowerUps() async {
    final data =
        await AssetResolver.instance.loadString('store-catalog/power-ups');
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => PowerUp.fromJson(json)).toList();
  }
}
