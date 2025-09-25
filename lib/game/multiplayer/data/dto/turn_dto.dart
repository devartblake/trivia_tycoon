class TurnDto {
  final String questionId;
  final int startAtMs; // epoch ms
  final int endAtMs;   // epoch ms

  const TurnDto({
    required this.questionId,
    required this.startAtMs,
    required this.endAtMs,
  });

  factory TurnDto.fromJson(Map<String, dynamic> j) => TurnDto(
    questionId: (j['questionId'] ?? '').toString(),
    startAtMs: (j['startAtMs'] is int)
        ? j['startAtMs'] as int
        : int.tryParse('${j['startAtMs'] ?? 0}') ?? 0,
    endAtMs: (j['endAtMs'] is int)
        ? j['endAtMs'] as int
        : int.tryParse('${j['endAtMs'] ?? 0}') ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'startAtMs': startAtMs,
    'endAtMs': endAtMs,
  };
}
