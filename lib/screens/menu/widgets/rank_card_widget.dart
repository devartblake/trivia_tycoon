import 'package:flutter/material.dart';
import '../../menu/widgets/rank_level_card.dart';

/// Wrapper for RankLevelCard with modern styling
///
/// This widget wraps the existing RankLevelCard component
/// and provides a consistent interface for the modular menu structure.
class RankCardWidget extends StatelessWidget {
  final int level;
  final String? rank;
  final int? currentXP;
  final int? maxXP;
  final String ageGroup;

  const RankCardWidget({
    super.key,
    required this.level,
    this.rank,
    this.currentXP,
    this.maxXP,
    required this.ageGroup,
  });

  @override
  Widget build(BuildContext context) {
    return RankLevelCard(
      level: level,
      rank: rank,
      currentXP: currentXP,
      maxXP: maxXP,
      ageGroup: ageGroup,
    );
  }
}