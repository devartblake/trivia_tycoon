import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/logic/quiz_completion_handler.dart';
import '../../game/services/educational_stats_service.dart';

class EducationalStatsInitializer {
  /// Initialize educational statistics service when app starts
  /// Call this in your main.dart or app initialization
  static Future<void> initialize(WidgetRef ref) async {
    try {
      final educationalStatsService = ref.read(educationalStatsServiceProvider);
      await educationalStatsService.initialize();

      debugPrint('Educational statistics service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize educational statistics service: $e');
      // Don't throw - app should continue even if stats fail to initialize
    }
  }

  /// Initialize with ProviderContainer (for app startup)
  static Future<void> initializeWithContainer(ProviderContainer container) async {
    try {
      final educationalStatsService = container.read(educationalStatsServiceProvider);
      await educationalStatsService.initialize();

      debugPrint('Educational statistics service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize educational statistics service: $e');
      // Don't throw - app should continue even if stats fail to initialize
    }
  }

  /// Helper method to test the integration with sample data
  /// Use this for testing the profile integration
  // static Future<void> addSampleQuizData(WidgetRef ref) async {
  //   try {
  //     // Add some sample quiz results for testing
  //     final sampleQuizzes = [
  //       {
  //         'category': 'Mathematics',
  //         'score': 8,
  //         'totalQuestions': 10,
  //         'classLevel': '10th Grade',
  //       },
  //       {
  //         'category': 'Science',
  //         'score': 7,
  //         'totalQuestions': 10,
  //         'classLevel': '10th Grade',
  //       },
  //       {
  //         'category': 'History',
  //         'score': 9,
  //         'totalQuestions': 10,
  //         'classLevel': '10th Grade',
  //       },
  //       {
  //         'category': 'Mathematics',
  //         'score': 6,
  //         'totalQuestions': 8,
  //         'classLevel': '10th Grade',
  //       },
  //       {
  //         'category': 'Science',
  //         'score': 10,
  //         'totalQuestions': 10,
  //         'classLevel': '10th Grade',
  //       },
  //     ];
  //
  //     for (final quiz in sampleQuizzes) {
  //       await ProfileDataUpdater.simulateQuizCompletion(
  //         ref,
  //         category: quiz['category'] as String,
  //         score: quiz['score'] as int,
  //         totalQuestions: quiz['totalQuestions'] as int,
  //         classLevel: quiz['classLevel'] as String,
  //       );
  //
  //       // Small delay between quizzes to simulate different days
  //       await Future.delayed(const Duration(milliseconds: 100));
  //     }
  //
  //     debugPrint('Sample quiz data added successfully');
  //   } catch (e) {
  //     debugPrint('Failed to add sample quiz data: $e');
  //   }
  // }
}
