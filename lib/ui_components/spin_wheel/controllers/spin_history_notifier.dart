import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/settings/app_settings.dart';
import '../models/spin_result.dart';

final spinHistoryProvider = AsyncNotifierProvider<SpinHistoryNotifier, List<SpinResult>>(
  SpinHistoryNotifier.new,
);

class SpinHistoryNotifier extends AsyncNotifier<List<SpinResult>> {
  static const _historyKey = 'spin_history';
  static const int _maxEntries = 50;

  @override
  Future<List<SpinResult>> build() async {
    final raw = await AppSettings.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> list = SpinResult.decodeList(raw);
    return list.cast<SpinResult>();
  }

  Future<void> add(SpinResult result) async {
    final current = await build();
    final updated = [result, ...current].take(20).toList(); // keep latest 20
    await AppSettings.setString(_historyKey, SpinResult.encodeList(updated));
    state = AsyncData(updated);
  }

  Future<void> clear() async {
    await AppSettings.remove(_historyKey);
    state = const AsyncData([]);
  }

  List<SpinResult> filterByDateRange(DateTime start, DateTime end) {
    return state.value
        ?.where((entry) =>
    entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end))
        .toList() ??
        [];
  }

  String getMostFrequentPrize() {
    final map = <String, int>{};
    for (final r in state.value ?? []) {
      map[r.label] = (map[r.label] ?? 0) + 1;
    }
    return map.isEmpty
        ? 'N/A'
        : map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
