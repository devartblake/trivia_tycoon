import 'package:flutter/material.dart';
import '../../game/models/question_model.dart';

class QuizHelpers {
  /// Get category-specific color scheme with light complementary backgrounds
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'science':
        return Colors.blue.shade600;
      case 'mathematics':
      case 'math':
        return Colors.purple.shade600;
      case 'language_arts':
      case 'literature':
        return Colors.green.shade600;
      case 'social_studies':
      case 'history':
        return Colors.orange.shade600;
      case 'arts_creativity':
      case 'arts':
        return Colors.pink.shade600;
      case 'health_wellness':
      case 'health':
        return Colors.red.shade600;
      case 'technology':
      case 'tech':
        return Colors.indigo.shade600;
      case 'critical_thinking':
      case 'psychology':
        return Colors.teal.shade600;
      case 'world_languages':
      case 'geography':
        return Colors.deepOrange.shade600;
      case 'entertainment':
        return Colors.cyan.shade600;
      case 'sports':
        return Colors.lime.shade700;
      case 'economics':
        return Colors.amber.shade700;
      case 'environment':
        return Colors.lightGreen.shade600;
      case 'law':
        return Colors.brown.shade600;
      case 'philosophy':
        return Colors.deepPurple.shade600;
      case 'politics':
        return Colors.blueGrey.shade600;
      case 'current_events':
        return Colors.grey.shade700;
      case 'media':
        return Colors.pinkAccent.shade400;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Get light complementary background color for categories
  static Color getCategoryBackgroundColor(String category) {
    switch (category.toLowerCase()) {
      case 'science':
        return Colors.blue.shade50;
      case 'mathematics':
      case 'math':
        return Colors.purple.shade50;
      case 'language_arts':
      case 'literature':
        return Colors.green.shade50;
      case 'social_studies':
      case 'history':
        return Colors.orange.shade50;
      case 'arts_creativity':
      case 'arts':
        return Colors.pink.shade50;
      case 'health_wellness':
      case 'health':
        return Colors.red.shade50;
      case 'technology':
      case 'tech':
        return Colors.indigo.shade50;
      case 'critical_thinking':
      case 'psychology':
        return Colors.teal.shade50;
      case 'world_languages':
      case 'geography':
        return Colors.deepOrange.shade50;
      case 'entertainment':
        return Colors.cyan.shade50;
      case 'sports':
        return Colors.lime.shade50;
      case 'economics':
        return Colors.amber.shade50;
      case 'environment':
        return Colors.lightGreen.shade50;
      case 'law':
        return Colors.brown.shade50;
      case 'philosophy':
        return Colors.deepPurple.shade50;
      case 'politics':
        return Colors.blueGrey.shade50;
      case 'current_events':
        return Colors.grey.shade50;
      case 'media':
        return Colors.pink.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  /// Get class-specific color scheme
  static Color getClassColor(String classLevel) {
    switch (classLevel.toLowerCase()) {
      case 'kindergarten':
      case 'k':
        return Colors.pink;
      case '1':
        return Colors.orange;
      case '2':
        return Colors.blue;
      case '3':
        return Colors.green;
      case '4':
        return Colors.purple;
      case '5':
        return Colors.teal;
      case '6':
        return Colors.indigo;
      case '7':
        return Colors.red;
      case '8':
        return Colors.brown;
      case '9':
        return Colors.cyan;
      case '10':
        return Colors.lime;
      case '11':
        return Colors.amber;
      case '12':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  /// Get timer color based on remaining time
  static Color getTimerColor(int timeRemaining) {
    if (timeRemaining <= 5) return Colors.red;
    if (timeRemaining <= 10) return Colors.orange;
    return Colors.green;
  }

  /// Get age-appropriate time limits
  static int getTimeLimitForClass(String classLevel) {
    switch (classLevel.toLowerCase()) {
      case 'kindergarten':
      case 'k':
        return 45;
      case '1':
        return 40;
      case '2':
        return 35;
      case '3':
      case '4':
      case '5':
        return 30;
      case '6':
      case '7':
      case '8':
        return 25;
      case '9':
      case '10':
      case '11':
      case '12':
        return 20;
      default:
        return 30;
    }
  }

  /// Get media type icon for question
  static IconData getMediaTypeIcon(QuestionModel question) {
    if (question.hasAudio) return Icons.headphones;
    if (question.hasVideo) return Icons.videocam;
    if (question.hasImage) return Icons.image;
    return Icons.text_fields;
  }

  /// Get media type color for question
  static Color getDisplayTypeColor(QuestionModel question) {
    if (question.hasAudio) return Colors.purple;
    if (question.hasVideo) return Colors.red;
    if (question.hasImage) return Colors.green;
    return Colors.blue;
  }

  /// Get display name for media type
  static String getDisplayTypeName(QuestionModel question) {
    if (question.hasAudio) return 'Audio';
    if (question.hasVideo) return 'Video';
    if (question.hasImage) return 'Image';
    return 'Text';
  }

  /// Get difficulty icon
  static IconData getDifficultyIcon(int difficulty) {
    switch (difficulty) {
      case 1: return Icons.star_outline;
      case 2: return Icons.star_half;
      case 3: return Icons.star;
      default: return Icons.help_outline;
    }
  }

  /// Get difficulty color
  static Color getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  /// Get difficulty text
  static String getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1: return 'easy';
      case 2: return 'medium';
      case 3: return 'hard';
      default: return 'unknown';
    }
  }

  /// Build metadata chip widget
  static Widget buildMetadataChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Get available power-ups for a question and class level
  static List<Map<String, dynamic>> getAvailablePowerUps(QuestionModel question, String classLevel) {
    final availablePowerUps = <Map<String, dynamic>>[];

    if (!question.showHint && question.powerUpHint?.isNotEmpty == true) {
      availablePowerUps.add({
        'type': 'hint',
        'icon': Icons.lightbulb,
        'color': Colors.orange,
        'label': 'Hint',
      });
    }

    if (question.reducedOptions == null && question.options.length > 2) {
      availablePowerUps.add({
        'type': 'eliminate',
        'icon': Icons.clear,
        'color': Colors.red,
        'label': '50/50',
      });
    }

    // Only show advanced power-ups for older students
    if (!['kindergarten', 'k', '1'].contains(classLevel.toLowerCase())) {
      if (!question.isBoostedTime) {
        availablePowerUps.add({
          'type': 'time_boost',
          'icon': Icons.speed,
          'color': Colors.blue,
          'label': 'Time+',
        });
      }

      if (!question.isShielded) {
        availablePowerUps.add({
          'type': 'shield',
          'icon': Icons.shield,
          'color': Colors.green,
          'label': 'Shield',
        });
      }
    }

    return availablePowerUps;
  }
}
