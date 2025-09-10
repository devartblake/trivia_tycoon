import 'package:flutter_riverpod/flutter_riverpod.dart';

class XPService {
  int _playerXP = 0;
  double _xpMultiplier = 1.0;
  DateTime? _boostExpiry;

  XPService({int startingPlayerXP = 0})
      : _playerXP = startingPlayerXP,
        _xpMultiplier = 1.0;

  // ---- Core getters ----
  int get playerXP => _playerXP;
  double get effectiveMultiplier => _xpMultiplier;
  bool get isBoostActive =>
      _boostExpiry != null && DateTime.now().isBefore(_boostExpiry!);

  Duration? boostRemaining() {
    if (!isBoostActive) return null;
    final d = _boostExpiry!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  // ---- XP operations ----
  bool hasEnoughXP(int xpCost) => _playerXP >= xpCost;

  void addXP(int baseAmount, {bool applyMultiplier = true}) {
    final effectiveAmount = applyMultiplier ? (baseAmount * _xpMultiplier).round() : baseAmount;
    _playerXP += effectiveAmount;
    // Optional: notify listeners or persist XP here
  }

  void deductXP(int xpCost) {
    _playerXP = (_playerXP - xpCost).clamp(0, 1 << 30);
  }

  // ---- Boost operations ----
  void setBonusMultiplier(double multiplier,
      {Duration? duration = const Duration(minutes: 10)}) {
    _xpMultiplier = multiplier;
    _boostExpiry = DateTime.now().add(duration!);
  }

  void applyTemporaryXPBoost(double multiplier,
      {Duration duration = const Duration(minutes: 15)}) {
    _xpMultiplier = multiplier.clamp(0.1, 100.0);
    _boostExpiry = DateTime.now().add(duration);
  }

  void resetXP() {
    _playerXP = 0;
    _xpMultiplier = 1.0;
    _boostExpiry = null;
  }

  /// Optional: call from a timer/tick to clear expired boost.
  void tick() {
    // Can be called on app loop or timer to expire boost
    if (_boostExpiry != null && DateTime.now().isAfter(_boostExpiry!)) {
      _xpMultiplier = 1.0;
      _boostExpiry = null;
    }
  }

  @override
  String toString() =>
      'XPService(xp=$_playerXP, multiplier=$_xpMultiplier, activeBoost=$isBoostActive, expire=$_boostExpiry)';
}

// River-pod provider
final xpServiceProvider = Provider<XPService>((ref) {
  return XPService(startingPlayerXP: 0);
});