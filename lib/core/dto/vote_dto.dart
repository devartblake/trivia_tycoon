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
        // Cast via Map (not Map<String, dynamic>) — nested map literals and
        // some decoders produce Map<dynamic, dynamic>.
        tally: (j['tally'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
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
