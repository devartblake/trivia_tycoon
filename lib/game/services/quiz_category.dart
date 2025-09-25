import 'package:flutter/material.dart';

/// Enum defining all available quiz categories
enum QuizCategory {
  // Core Academic Subjects
  arts,
  science,
  mathematics,
  history,
  geography,
  literature,
  technology,
  health,
  sports,
  entertainment,

  // Extended Academic Subjects
  economics,
  philosophy,
  psychology,
  politics,
  law,
  environment,
  currentEvents,
  media,
  socialStudies,

  // Specialized Subjects
  architecture,
  artHistory,
  astronomy,
  business,
  civicsLaw,
  comparativeReligions,
  computerScience,
  globalCultures,
  economicsFinance,
  engineeringTechnology,
  environmentalScience,
  healthMedicine,
  statisticsData,
  worldLiterature,

  // Educational Levels
  kids,
  kidsGrade2,
  general,
}

/// Extension to provide category metadata and utilities
extension QuizCategoryExtension on QuizCategory {
  /// Get the display name for the category
  String get displayName {
    switch (this) {
      case QuizCategory.arts:
        return 'Arts';
      case QuizCategory.science:
        return 'Science';
      case QuizCategory.mathematics:
        return 'Mathematics';
      case QuizCategory.history:
        return 'History';
      case QuizCategory.geography:
        return 'Geography';
      case QuizCategory.literature:
        return 'Literature';
      case QuizCategory.technology:
        return 'Technology';
      case QuizCategory.health:
        return 'Health';
      case QuizCategory.sports:
        return 'Sports';
      case QuizCategory.entertainment:
        return 'Entertainment';
      case QuizCategory.economics:
        return 'Economics';
      case QuizCategory.philosophy:
        return 'Philosophy';
      case QuizCategory.psychology:
        return 'Psychology';
      case QuizCategory.politics:
        return 'Politics';
      case QuizCategory.law:
        return 'Law';
      case QuizCategory.environment:
        return 'Environment';
      case QuizCategory.currentEvents:
        return 'Current Events';
      case QuizCategory.media:
        return 'Media';
      case QuizCategory.socialStudies:
        return 'Social Studies';
      case QuizCategory.architecture:
        return 'Architecture';
      case QuizCategory.artHistory:
        return 'Art History';
      case QuizCategory.astronomy:
        return 'Astronomy';
      case QuizCategory.business:
        return 'Business';
      case QuizCategory.civicsLaw:
        return 'Civics & Law';
      case QuizCategory.comparativeReligions:
        return 'Comparative Religions';
      case QuizCategory.computerScience:
        return 'Computer Science';
      case QuizCategory.globalCultures:
        return 'Global Cultures';
      case QuizCategory.economicsFinance:
        return 'Economics & Finance';
      case QuizCategory.engineeringTechnology:
        return 'Engineering & Technology';
      case QuizCategory.environmentalScience:
        return 'Environmental Science';
      case QuizCategory.healthMedicine:
        return 'Health & Medicine';
      case QuizCategory.statisticsData:
        return 'Statistics & Data';
      case QuizCategory.worldLiterature:
        return 'World Literature';
      case QuizCategory.kids:
        return 'Kids Questions';
      case QuizCategory.kidsGrade2:
        return 'Kids Grade 2';
      case QuizCategory.general:
        return 'General Knowledge';
    }
  }

  /// Get the description for the category
  String get description {
    switch (this) {
      case QuizCategory.arts:
        return 'Visual arts, music, theater, and creative expressions';
      case QuizCategory.science:
        return 'Physics, chemistry, biology, and scientific principles';
      case QuizCategory.mathematics:
        return 'Mathematical concepts, problems, and applications';
      case QuizCategory.history:
        return 'Historical events, civilizations, and world history';
      case QuizCategory.geography:
        return 'World geography, countries, capitals, and landmarks';
      case QuizCategory.literature:
        return 'Books, authors, poetry, and literary works';
      case QuizCategory.technology:
        return 'Computing, programming, and modern technology';
      case QuizCategory.health:
        return 'Health, medicine, nutrition, and wellness';
      case QuizCategory.sports:
        return 'Sports, athletics, games, and fitness';
      case QuizCategory.entertainment:
        return 'Movies, music, celebrities, and popular culture';
      case QuizCategory.economics:
        return 'Economic principles, markets, and financial concepts';
      case QuizCategory.philosophy:
        return 'Philosophical concepts, ethics, and critical thinking';
      case QuizCategory.psychology:
        return 'Psychological concepts, behavior, and mental processes';
      case QuizCategory.politics:
        return 'Political systems, governance, and civic knowledge';
      case QuizCategory.law:
        return 'Legal concepts, rights, and judicial systems';
      case QuizCategory.environment:
        return 'Environmental science, climate, and sustainability';
      case QuizCategory.currentEvents:
        return 'Recent news, current affairs, and contemporary issues';
      case QuizCategory.media:
        return 'Media, journalism, communication, and digital platforms';
      case QuizCategory.socialStudies:
        return 'Social sciences, sociology, and human behavior';
      case QuizCategory.architecture:
        return 'Architecture, building design, and structural concepts';
      case QuizCategory.artHistory:
        return 'History of art, artistic movements, and famous artworks';
      case QuizCategory.astronomy:
        return 'Space, stars, planets, and astronomical phenomena';
      case QuizCategory.business:
        return 'Business concepts, entrepreneurship, and management';
      case QuizCategory.civicsLaw:
        return 'Civic duties, government, and basic legal concepts';
      case QuizCategory.comparativeReligions:
        return 'World religions, beliefs, and spiritual practices';
      case QuizCategory.computerScience:
        return 'Programming, algorithms, and computer science concepts';
      case QuizCategory.globalCultures:
        return 'World cultures, traditions, and cultural studies';
      case QuizCategory.economicsFinance:
        return 'Advanced economics and financial concepts';
      case QuizCategory.engineeringTechnology:
        return 'Engineering principles and technological applications';
      case QuizCategory.environmentalScience:
        return 'Advanced environmental science and ecological studies';
      case QuizCategory.healthMedicine:
        return 'Medical science, healthcare, and advanced health topics';
      case QuizCategory.statisticsData:
        return 'Statistics, data analysis, and data literacy';
      case QuizCategory.worldLiterature:
        return 'International literature and global literary works';
      case QuizCategory.kids:
        return 'Age-appropriate questions for children and families';
      case QuizCategory.kidsGrade2:
        return 'Specific questions designed for grade 2 students';
      case QuizCategory.general:
        return 'Mixed categories and general knowledge';
    }
  }

  /// Get the primary color for the category
  Color get primaryColor {
    switch (this) {
      case QuizCategory.arts:
        return Colors.pink.shade600;
      case QuizCategory.science:
        return Colors.blue.shade600;
      case QuizCategory.mathematics:
        return Colors.purple.shade600;
      case QuizCategory.history:
        return Colors.brown.shade600;
      case QuizCategory.geography:
        return Colors.teal.shade600;
      case QuizCategory.literature:
        return Colors.green.shade600;
      case QuizCategory.technology:
        return Colors.indigo.shade600;
      case QuizCategory.health:
        return Colors.red.shade600;
      case QuizCategory.sports:
        return Colors.orange.shade600;
      case QuizCategory.entertainment:
        return Colors.deepPurple.shade600;
      case QuizCategory.economics:
        return Colors.amber.shade700;
      case QuizCategory.philosophy:
        return Colors.blueGrey.shade600;
      case QuizCategory.psychology:
        return Colors.cyan.shade600;
      case QuizCategory.politics:
        return Colors.deepOrange.shade600;
      case QuizCategory.law:
        return Colors.grey.shade700;
      case QuizCategory.environment:
        return Colors.lightGreen.shade600;
      case QuizCategory.currentEvents:
        return Colors.lime.shade700;
      case QuizCategory.media:
        return Colors.purple.shade400;
      case QuizCategory.socialStudies:
        return Colors.blue.shade400;
      case QuizCategory.architecture:
        return Colors.blueGrey.shade700;
      case QuizCategory.artHistory:
        return Colors.pink.shade400;
      case QuizCategory.astronomy:
        return Colors.indigo.shade800;
      case QuizCategory.business:
        return Colors.green.shade700;
      case QuizCategory.civicsLaw:
        return Colors.red.shade700;
      case QuizCategory.comparativeReligions:
        return Colors.deepPurple.shade400;
      case QuizCategory.computerScience:
        return Colors.blue.shade800;
      case QuizCategory.globalCultures:
        return Colors.orange.shade700;
      case QuizCategory.economicsFinance:
        return Colors.green.shade800;
      case QuizCategory.engineeringTechnology:
        return Colors.grey.shade600;
      case QuizCategory.environmentalScience:
        return Colors.green.shade500;
      case QuizCategory.healthMedicine:
        return Colors.red.shade500;
      case QuizCategory.statisticsData:
        return Colors.cyan.shade700;
      case QuizCategory.worldLiterature:
        return Colors.teal.shade400;
      case QuizCategory.kids:
        return Colors.yellow.shade600;
      case QuizCategory.kidsGrade2:
        return Colors.orange.shade400;
      case QuizCategory.general:
        return Colors.grey.shade500;
    }
  }

  /// Get the icon for the category
  IconData get icon {
    switch (this) {
      case QuizCategory.arts:
        return Icons.palette;
      case QuizCategory.science:
        return Icons.science;
      case QuizCategory.mathematics:
        return Icons.calculate;
      case QuizCategory.history:
        return Icons.history_edu;
      case QuizCategory.geography:
        return Icons.public;
      case QuizCategory.literature:
        return Icons.menu_book;
      case QuizCategory.technology:
        return Icons.computer;
      case QuizCategory.health:
        return Icons.favorite;
      case QuizCategory.sports:
        return Icons.sports_soccer;
      case QuizCategory.entertainment:
        return Icons.movie;
      case QuizCategory.economics:
        return Icons.trending_up;
      case QuizCategory.philosophy:
        return Icons.psychology;
      case QuizCategory.psychology:
        return Icons.psychology_alt;
      case QuizCategory.politics:
        return Icons.account_balance;
      case QuizCategory.law:
        return Icons.gavel;
      case QuizCategory.environment:
        return Icons.eco;
      case QuizCategory.currentEvents:
        return Icons.newspaper;
      case QuizCategory.media:
        return Icons.tv;
      case QuizCategory.socialStudies:
        return Icons.groups;
      case QuizCategory.architecture:
        return Icons.architecture;
      case QuizCategory.artHistory:
        return Icons.museum;
      case QuizCategory.astronomy:
        return Icons.star;
      case QuizCategory.business:
        return Icons.business;
      case QuizCategory.civicsLaw:
        return Icons.how_to_vote;
      case QuizCategory.comparativeReligions:
        return Icons.church;
      case QuizCategory.computerScience:
        return Icons.code;
      case QuizCategory.globalCultures:
        return Icons.language;
      case QuizCategory.economicsFinance:
        return Icons.attach_money;
      case QuizCategory.engineeringTechnology:
        return Icons.engineering;
      case QuizCategory.environmentalScience:
        return Icons.nature;
      case QuizCategory.healthMedicine:
        return Icons.medical_services;
      case QuizCategory.statisticsData:
        return Icons.analytics;
      case QuizCategory.worldLiterature:
        return Icons.auto_stories;
      case QuizCategory.kids:
        return Icons.child_care;
      case QuizCategory.kidsGrade2:
        return Icons.school;
      case QuizCategory.general:
        return Icons.quiz;
    }
  }

  /// Get the dataset name for loading questions
  String get datasetName {
    switch (this) {
      case QuizCategory.arts:
        return 'Arts';
      case QuizCategory.science:
        return 'Science';
      case QuizCategory.mathematics:
        return 'Mathematics';
      case QuizCategory.history:
        return 'History';
      case QuizCategory.geography:
        return 'Geography';
      case QuizCategory.literature:
        return 'Literature';
      case QuizCategory.technology:
        return 'Technology';
      case QuizCategory.health:
        return 'Health';
      case QuizCategory.sports:
        return 'Sports';
      case QuizCategory.entertainment:
        return 'Entertainment';
      case QuizCategory.economics:
        return 'Economics';
      case QuizCategory.philosophy:
        return 'Philosophy';
      case QuizCategory.psychology:
        return 'Psychology';
      case QuizCategory.politics:
        return 'Politics';
      case QuizCategory.law:
        return 'Law';
      case QuizCategory.environment:
        return 'Environment';
      case QuizCategory.currentEvents:
        return 'Current Events';
      case QuizCategory.media:
        return 'Media';
      case QuizCategory.socialStudies:
        return 'Social Studies';
      case QuizCategory.architecture:
        return 'Architecture';
      case QuizCategory.artHistory:
        return 'Art History';
      case QuizCategory.astronomy:
        return 'Astronomy';
      case QuizCategory.business:
        return 'Business';
      case QuizCategory.civicsLaw:
        return 'Civics & Law';
      case QuizCategory.comparativeReligions:
        return 'Comparative Religions';
      case QuizCategory.computerScience:
        return 'Computer Science';
      case QuizCategory.globalCultures:
        return 'Global Cultures';
      case QuizCategory.economicsFinance:
        return 'Economics & Finance';
      case QuizCategory.engineeringTechnology:
        return 'Engineering & Technology';
      case QuizCategory.environmentalScience:
        return 'Environmental Science';
      case QuizCategory.healthMedicine:
        return 'Health & Medicine';
      case QuizCategory.statisticsData:
        return 'Statistics & Data';
      case QuizCategory.worldLiterature:
        return 'World Literature';
      case QuizCategory.kids:
        return 'Kids Questions';
      case QuizCategory.kidsGrade2:
        return 'Kids Grade 2';
      case QuizCategory.general:
        return 'General Knowledge';
    }
  }

  /// Get background gradient colors for the category
  List<Color> get gradientColors {
    return [
      primaryColor,
      primaryColor.withOpacity(0.7),
    ];
  }
}

/// Utility class for category management
class QuizCategoryManager {
  /// Get all core academic categories
  static List<QuizCategory> get coreCategories => [
    QuizCategory.arts,
    QuizCategory.science,
    QuizCategory.mathematics,
    QuizCategory.history,
    QuizCategory.geography,
    QuizCategory.literature,
    QuizCategory.technology,
    QuizCategory.health,
    QuizCategory.sports,
    QuizCategory.entertainment,
  ];

  /// Get all extended academic categories
  static List<QuizCategory> get extendedCategories => [
    QuizCategory.economics,
    QuizCategory.philosophy,
    QuizCategory.psychology,
    QuizCategory.politics,
    QuizCategory.law,
    QuizCategory.environment,
    QuizCategory.currentEvents,
    QuizCategory.media,
    QuizCategory.socialStudies,
  ];

  /// Get all specialized categories
  static List<QuizCategory> get specializedCategories => [
    QuizCategory.architecture,
    QuizCategory.artHistory,
    QuizCategory.astronomy,
    QuizCategory.business,
    QuizCategory.civicsLaw,
    QuizCategory.comparativeReligions,
    QuizCategory.computerScience,
    QuizCategory.globalCultures,
    QuizCategory.economicsFinance,
    QuizCategory.engineeringTechnology,
    QuizCategory.environmentalScience,
    QuizCategory.healthMedicine,
    QuizCategory.statisticsData,
    QuizCategory.worldLiterature,
  ];

  /// Get all educational level categories
  static List<QuizCategory> get educationalCategories => [
    QuizCategory.kids,
    QuizCategory.kidsGrade2,
    QuizCategory.general,
  ];

  /// Get all categories
  static List<QuizCategory> get allCategories => [
    ...coreCategories,
    ...extendedCategories,
    ...specializedCategories,
    ...educationalCategories,
  ];

  /// Parse string to QuizCategory
  static QuizCategory? fromString(String categoryString) {
    final normalized = categoryString.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');

    for (final category in QuizCategory.values) {
      final categoryName = category.name.toLowerCase();
      final displayName = category.displayName.toLowerCase().replaceAll(' ', '').replaceAll('_', '').replaceAll('-', '');

      if (categoryName == normalized || displayName == normalized) {
        return category;
      }
    }

    // Handle special cases
    switch (normalized) {
      case 'math':
      case 'maths':
        return QuizCategory.mathematics;
      case 'tech':
      case 'computing':
        return QuizCategory.technology;
      case 'social':
      case 'socialstudies':
        return QuizCategory.socialStudies;
      case 'currentaffairs':
      case 'news':
        return QuizCategory.currentEvents;
      case 'generalknowledge':
      case 'mixed':
        return QuizCategory.general;
      case 'arthistory':
        return QuizCategory.artHistory;
      case 'computerscience':
      case 'cs':
        return QuizCategory.computerScience;
      case 'environmentalscience':
        return QuizCategory.environmentalScience;
      case 'healthmedicine':
        return QuizCategory.healthMedicine;
      case 'worldliterature':
        return QuizCategory.worldLiterature;
      default:
        return null;
    }
  }

  /// Get categories suitable for a specific class/grade level
  static List<QuizCategory> getCategoriesForClass(String classLevel) {
    final level = int.tryParse(classLevel) ?? 1;

    if (level <= 2) {
      return [
        QuizCategory.kids,
        QuizCategory.kidsGrade2,
        QuizCategory.arts,
        QuizCategory.mathematics,
        QuizCategory.science,
      ];
    } else if (level <= 5) {
      return [
        QuizCategory.arts,
        QuizCategory.mathematics,
        QuizCategory.science,
        QuizCategory.history,
        QuizCategory.geography,
        QuizCategory.health,
      ];
    } else if (level <= 8) {
      return [
        ...coreCategories,
        QuizCategory.socialStudies,
        QuizCategory.environment,
      ];
    } else {
      return allCategories;
    }
  }

  /// Filter categories by search query
  static List<QuizCategory> searchCategories(String query) {
    if (query.isEmpty) return allCategories;

    final queryLower = query.toLowerCase();
    return allCategories.where((category) {
      return category.displayName.toLowerCase().contains(queryLower) ||
          category.description.toLowerCase().contains(queryLower);
    }).toList();
  }
}