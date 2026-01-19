import 'package:flutter/material.dart';
import '../sections/recently_played_section.dart';

/// Wrapper for RecentlyPlayedSection with modern styling
///
/// This widget wraps the existing RecentlyPlayedSection component
/// and provides a consistent interface for the modular menu structure.
class RecentlyPlayedWidget extends StatelessWidget {
  final List<Map<String, String>> quizzes;
  final String ageGroup;

  const RecentlyPlayedWidget({
    super.key,
    this.quizzes = const [],
    this.ageGroup = 'general',
  });

  @override
  Widget build(BuildContext context) {
    return RecentlyPlayedSection(
      quizzes: quizzes,
      ageGroup: ageGroup,
    );
  }
}