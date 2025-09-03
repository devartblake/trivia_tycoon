import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/controllers/coin_balance_notifier.dart';
import '../states/admin_filter_state.dart';

class AdminFilterController extends StateNotifier<AdminFilterState> {
  final Ref ref;

  AdminFilterController(this.ref) : super(AdminFilterState());

  void setVerified(bool value) => state = state.copyWith(showVerified: value);
  void setPremium(bool value) => state = state.copyWith(showPremium: value);
  void setBots(bool value) => state = state.copyWith(showBots: value);
  void setPowerUsers(bool value) => state = state.copyWith(showPowerUsers: value);

  void toggleDeviceType(String device) {
    final updated = {...state.deviceTypes};
    updated.contains(device) ? updated.remove(device) : updated.add(device);
    state = state.copyWith(deviceTypes: updated);
  }

  void setNotificationMethod(String? method) {
    if (method != null) {
      state = state.copyWith(notificationMethod: method);
    }
  }

  Future<void> saveToStorage() async {
    final storage = ref.read(generalKeyValueStorageProvider);
    await storage.setString('leaderboard_filters', jsonEncode(state.toJson()));
  }

  Future<void> loadFromStorage() async {
    final storage = ref.read(generalKeyValueStorageProvider);
    final json = await storage.getString('leaderboard_filters');
    if (json != null) {
      state = AdminFilterState.fromJson(jsonDecode(json));
    }
  }
}