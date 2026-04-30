import '../../dto/personalization_dto.dart';

/// Session-scoped in-memory store for A/B experiment assignments.
///
/// Seeded once at session start from GET /experiments/player/{id}.
/// Experiments are treated as opaque strings; missing keys return null (→ control).
class ExperimentStore {
  ExperimentStore._();

  static final ExperimentStore instance = ExperimentStore._();

  final Map<String, ExperimentAssignmentDto> _assignments = {};
  bool _seeded = false;

  /// Seed the store from the session-start bootstrap response.
  /// Calling this a second time within a session overwrites all assignments.
  void seed(List<ExperimentAssignmentDto> assignments) {
    _assignments
      ..clear()
      ..addEntries(assignments.map((a) => MapEntry(a.experimentKey, a)));
    _seeded = true;
  }

  /// Look up an assignment by key. Returns null when not enrolled or not seeded.
  ExperimentAssignmentDto? get(String experimentKey) => _assignments[experimentKey];

  /// Whether [experimentKey] is enrolled in a non-control variant.
  bool isInVariant(String experimentKey) {
    final a = _assignments[experimentKey];
    return a != null && !a.isControl;
  }

  bool get isSeeded => _seeded;

  void clear() {
    _assignments.clear();
    _seeded = false;
  }
}
