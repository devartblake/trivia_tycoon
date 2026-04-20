class EnergyState {
  final int current;
  final int max;
  final DateTime? lastRefill;

  EnergyState({
    required this.current,
    required this.max,
    this.lastRefill,
  });
}
