import 'reactor_reward_line.dart';

class ReactorRewardPreview {
  final String rewardId;
  final String displayName;
  final List<ReactorRewardLine> lines;

  const ReactorRewardPreview({
    required this.rewardId,
    required this.displayName,
    required this.lines,
  });

  factory ReactorRewardPreview.fromJson(Map<String, dynamic> json) {
    return ReactorRewardPreview(
      rewardId: json['rewardId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      lines: (json['lines'] as List? ?? const [])
          .map((e) =>
              ReactorRewardLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rewardId': rewardId,
        'displayName': displayName,
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}
