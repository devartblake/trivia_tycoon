class VoteResultDto {
  final String topic;
  final Map<String, int> tally;
  final int totalVotes;
  final String? winningChoice;

  const VoteResultDto({
    required this.topic,
    required this.tally,
    required this.totalVotes,
    this.winningChoice,
  });

  factory VoteResultDto.fromJson(Map<String, dynamic> j) => VoteResultDto(
    topic: j['topic'] as String,
    tally: (j['tally'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
    ) ??
        {},
    totalVotes: j['totalVotes'] as int? ?? 0,
    winningChoice: j['winningChoice'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'tally': tally,
    'totalVotes': totalVotes,
    'winningChoice': winningChoice,
  };
}