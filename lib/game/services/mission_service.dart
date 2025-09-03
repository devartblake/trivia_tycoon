import 'package:hive/hive.dart';

class MissionService {
  static const _boxKey = 'mission_data';

  Future<void> saveMissions(List<Map<String, dynamic>> missions) async {
    final box = await Hive.openBox(_boxKey);
    await box.put('currentMissions', missions);
  }

  Future<List<Map<String, dynamic>>> loadMissions() async {
    final box = await Hive.openBox(_boxKey);
    return List<Map<String, dynamic>>.from(box.get('currentMissions', defaultValue: []));
  }

  Future<void> clearMissions() async {
    final box = await Hive.openBox(_boxKey);
    await box.delete('currentMissions');
  }
}
