import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../game/models/power_up.dart';

class PowerUpService {
  static Future<List<PowerUp>> loadPowerUps() async {
    final data = await rootBundle.loadString('assets/data/power_ups.json');
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => PowerUp.fromJson(json)).toList();
  }
}