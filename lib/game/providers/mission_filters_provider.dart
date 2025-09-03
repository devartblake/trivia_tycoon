import 'package:flutter_riverpod/flutter_riverpod.dart';

class MissionFilters {
  final String userType;
  final String timeframe;

  MissionFilters({
    this.userType = 'All',
    this.timeframe = 'Daily',
  });

  MissionFilters copyWith({String? userType, String? timeframe}) {
    return MissionFilters(
      userType: userType ?? this.userType,
      timeframe: timeframe ?? this.timeframe,
    );
  }
}

class MissionFiltersNotifier extends StateNotifier<MissionFilters> {
  MissionFiltersNotifier() : super(MissionFilters());

  void updateUserType(String userType) {
    state = state.copyWith(userType: userType);
  }

  void updateTimeframe(String timeframe) {
    state = state.copyWith(timeframe: timeframe);
  }
}

final missionFiltersProvider = StateNotifierProvider<MissionFiltersNotifier, MissionFilters>(
      (ref) => MissionFiltersNotifier(),
);
