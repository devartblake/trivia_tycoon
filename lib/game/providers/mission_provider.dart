import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mission_model.dart';

final dailyMissionsProvider = StateProvider<List<Mission>>((ref) => [
  Mission(
    title: "Answer 3 Daily Questions",
    progress: 2,
    total: 3,
    reward: 300,
    icon: Icons.calendar_today,
    badge: "Daily",
    type: MissionType.daily,
  ),
]);

final weeklyMissionsProvider = StateProvider<List<Mission>>((ref) => [
  Mission(
    title: "Win 10 Trivia Games",
    progress: 4,
    total: 10,
    reward: 1000,
    icon: Icons.event,
    badge: "Weekly",
    type: MissionType.weekly,
  ),
]);