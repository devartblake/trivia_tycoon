class LivesState {
  final int current;
  final int max;
  final DateTime? lastRefill;

  LivesState({
    required this.current,
    required this.max,
    this.lastRefill,
  });
}