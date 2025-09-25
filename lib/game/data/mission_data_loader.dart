import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod_providers.dart';

// Age group enum
enum AgeGroup { children, adolescence, adults }

// Mission data loader service
class MissionDataLoader {
  static const Map<AgeGroup, String> _assetPaths = {
    AgeGroup.children: 'assets/data/missions/children_missions.json',
    AgeGroup.adolescence: 'assets/data/missions/adolescence_missions.json',
    AgeGroup.adults: 'assets/data/missions/adults_missions.json',
  };

  static final Map<AgeGroup, List<Map<String, dynamic>>> _cachedMissions = {};

  // Load missions for specific age group
  static Future<List<Map<String, dynamic>>> loadMissionsForAge(AgeGroup ageGroup) async {
    // Return cached if available
    if (_cachedMissions.containsKey(ageGroup)) {
      return _cachedMissions[ageGroup]!;
    }

    try {
      final String jsonString = await rootBundle.loadString(_assetPaths[ageGroup]!);
      final List<dynamic> jsonList = json.decode(jsonString);

      final List<Map<String, dynamic>> missions = jsonList.map((json) {
        return _convertJsonToMissionMap(json);
      }).toList();

      // Cache for future use
      _cachedMissions[ageGroup] = missions;
      return missions;
    } catch (e) {
      debugPrint('Error loading missions for $ageGroup: $e');
      return _getFallbackMissions(ageGroup);
    }
  }

  // Convert JSON mission to the format your MissionPanel expects
  static Map<String, dynamic> _convertJsonToMissionMap(Map<String, dynamic> json) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
      'title': json['title'] as String,
      'progress': json['progress'] as int? ?? 0,
      'total': json['total'] as int,
      'reward': json['reward'] as int,
      'icon': _getIconFromString(json['icon'] as String),
      'badge': json['badge'] as String,
      'mode': json['mode'] as String?,
      'category': json['category'] as String?,
      'difficulty': json['difficulty'] as int? ?? 1,
      'tags': List<String>.from(json['tags'] as List? ?? []),
    };
  }

  // Convert icon string to IconData
  static IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'science':
        return Icons.science;
      case 'palette':
        return Icons.palette;
      case 'movie':
        return Icons.movie;
      case 'menu_book':
        return Icons.menu_book;
      case 'history_edu':
        return Icons.history_edu;
      case 'memory':
        return Icons.memory;
      case 'eco':
        return Icons.eco;
      case 'public':
        return Icons.public;
      case 'quiz':
        return Icons.quiz;
      case 'sports_esports':
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'flash_on':
        return Icons.flash_on;
      case 'filter_vintage':
        return Icons.filter_vintage;
      case 'check_circle':
        return Icons.check_circle;
      case 'verified':
        return Icons.verified;
      case 'military_tech':
        return Icons.military_tech;
      case 'timer':
        return Icons.timer;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'bolt':
        return Icons.bolt;
      case 'groups':
        return Icons.groups;
      case 'today':
        return Icons.today;
      default:
        return Icons.assignment;
    }
  }

  // Fallback missions if JSON loading fails
  static List<Map<String, dynamic>> _getFallbackMissions(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.children:
        return [
          {
            'id': 'fallback-1',
            'title': 'Answer 3 Science questions',
            'progress': 0,
            'total': 3,
            'reward': 200,
            'icon': Icons.science,
            'badge': 'Science Starter'
          },
        ];
      case AgeGroup.adolescence:
        return [
          {
            'id': 'fallback-2',
            'title': 'Answer 10 Science questions correctly',
            'progress': 0,
            'total': 10,
            'reward': 500,
            'icon': Icons.science,
            'badge': 'Science Pro'
          },
        ];
      case AgeGroup.adults:
        return [
          {
            'id': 'fallback-3',
            'title': 'Answer 20 Science questions correctly',
            'progress': 0,
            'total': 20,
            'reward': 1000,
            'icon': Icons.science,
            'badge': 'Science Expert'
          },
        ];
    }
  }

  // Get random missions from age group
  static List<Map<String, dynamic>> selectRandomMissions(
      List<Map<String, dynamic>> allMissions,
      int count,
      {String? preferredMode, String? preferredCategory}
      ) {
    List<Map<String, dynamic>> filteredMissions = [...allMissions];

    // Filter by mode if specified
    if (preferredMode != null) {
      final modeFiltered = filteredMissions.where((m) => m['mode'] == preferredMode).toList();
      if (modeFiltered.isNotEmpty) {
        filteredMissions = modeFiltered;
      }
    }

    // Filter by category if specified
    if (preferredCategory != null) {
      final categoryFiltered = filteredMissions.where((m) => m['category'] == preferredCategory).toList();
      if (categoryFiltered.isNotEmpty) {
        filteredMissions = categoryFiltered;
      }
    }

    // Shuffle and take the requested count
    filteredMissions.shuffle();
    return filteredMissions.take(count).toList();
  }
}

// Age-aware mission notifier
class LiveMissionsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final AgeGroup _ageGroup;
  List<Map<String, dynamic>> _allAvailableMissions = [];

  LiveMissionsNotifier(this._ageGroup) : super([]) {
    _initializeMissions();
  }

  Future<void> _initializeMissions() async {
    // Load all missions for this age group
    _allAvailableMissions = await MissionDataLoader.loadMissionsForAge(_ageGroup);

    // Select initial random missions
    await generateNewMissions();
  }

  // Generate new set of missions
  Future<void> generateNewMissions({
    int count = 5,
    String? preferredMode,
    String? preferredCategory,
  }) async {
    if (_allAvailableMissions.isEmpty) {
      _allAvailableMissions = await MissionDataLoader.loadMissionsForAge(_ageGroup);
    }

    final selectedMissions = MissionDataLoader.selectRandomMissions(
      _allAvailableMissions,
      count,
      preferredMode: preferredMode,
      preferredCategory: preferredCategory,
    );

    // Give each mission a unique ID and reset progress
    final missionsWithIds = selectedMissions.map((mission) {
      return {
        ...mission,
        'id': DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(10000).toString(),
        'progress': 0, // Reset progress for new missions
      };
    }).toList();

    state = missionsWithIds;
  }

  // Swap a specific mission
  Future<void> swapMission(String missionId) async {
    final currentMissions = [...state];
    final missionIndex = currentMissions.indexWhere((m) => m['id'] == missionId);

    if (missionIndex == -1) return;

    // Get a replacement mission that's different from current ones
    final currentTitles = currentMissions.map((m) => m['title']).toSet();
    final availableReplacements = _allAvailableMissions
        .where((m) => !currentTitles.contains(m['title']))
        .toList();

    if (availableReplacements.isEmpty) {
      // If no different missions available, just shuffle the existing ones
      availableReplacements.addAll(_allAvailableMissions);
    }

    availableReplacements.shuffle();
    final replacement = availableReplacements.first;

    // Create new mission with unique ID and reset progress
    final newMission = {
      ...replacement,
      'id': DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(10000).toString(),
      'progress': 0,
    };

    currentMissions[missionIndex] = newMission;
    state = currentMissions;
  }

  // Update mission progress
  void updateMissionProgress(String missionId, int progressIncrement) {
    final updatedMissions = state.map((mission) {
      if (mission['id'] == missionId) {
        final newProgress = (mission['progress'] as int) + progressIncrement;
        return {
          ...mission,
          'progress': newProgress.clamp(0, mission['total'] as int),
        };
      }
      return mission;
    }).toList();

    state = updatedMissions;
  }

  // Track user action and update relevant missions
  void trackUserAction(String actionType, Map<String, dynamic> metadata) {
    final mode = metadata['mode'] as String?;
    final category = metadata['category'] as String?;

    switch (actionType) {
      case 'question_correct':
        _updateMissionsByAction('category', category, mode, 1);
        break;
      case 'streak_achieved':
        final streakLength = metadata['streak_length'] as int? ?? 1;
        _updateMissionsByTag('streak', streakLength);
        break;
      case 'combo_triggered':
        _updateMissionsByTag('combo', 1);
        break;
      case 'accuracy_maintained':
        _updateMissionsByTag('accuracy', 1);
        break;
      case 'perfect_round':
        _updateMissionsByTag('perfect', 1);
        break;
      case 'fast_answer':
        _updateMissionsByTag('speed', 1);
        break;
      case 'survival_progress':
        final questionsAnswered = metadata['questions_answered'] as int? ?? 1;
        _updateMissionsByTag('survival', questionsAnswered);
        break;
      case 'lifeline_used':
        _updateMissionsByTag('powerups', 1);
        break;
      case 'multiplayer_game':
        _updateMissionsByTag('multiplayer', 1);
        break;
      case 'daily_mission_completed':
        _updateMissionsByTag('daily', 1);
        break;
      case 'category_variety':
        _updateMissionsByTag('variety', 1);
        break;
    }
  }

  void _updateMissionsByAction(String type, String? value, String? mode, int increment) {
    if (value == null) return;

    final updatedMissions = state.map((mission) {
      bool shouldUpdate = false;

      if (type == 'category' && mission['category'] == value) {
        // Also check mode if specified in mission
        if (mission['mode'] == null || mission['mode'] == mode) {
          shouldUpdate = true;
        }
      }

      if (shouldUpdate) {
        final newProgress = (mission['progress'] as int) + increment;
        return {
          ...mission,
          'progress': newProgress.clamp(0, mission['total'] as int),
        };
      }
      return mission;
    }).toList();

    state = updatedMissions;
  }

  void _updateMissionsByTag(String tag, int increment) {
    final updatedMissions = state.map((mission) {
      final tags = mission['tags'] as List<String>? ?? [];

      if (tags.contains(tag)) {
        final newProgress = (mission['progress'] as int) + increment;
        return {
          ...mission,
          'progress': newProgress.clamp(0, mission['total'] as int),
        };
      }
      return mission;
    }).toList();

    state = updatedMissions;
  }

  // Get missions by specific criteria
  List<Map<String, dynamic>> getMissionsByMode(String mode) {
    return state.where((m) => m['mode'] == mode).toList();
  }

  List<Map<String, dynamic>> getMissionsByCategory(String category) {
    return state.where((m) => m['category'] == category).toList();
  }

  List<Map<String, dynamic>> getMissionsByDifficulty(int difficulty) {
    return state.where((m) => m['difficulty'] == difficulty).toList();
  }
}

class MissionActions {
  final Ref _ref;

  MissionActions(this._ref);

  Future<void> swapMission(String missionId) async {
    final ageGroup = _ref.read(currentUserAgeGroupProvider);

    switch (ageGroup) {
      case AgeGroup.children:
        await _ref.read(childrenMissionsProvider.notifier).swapMission(missionId);
        break;
      case AgeGroup.adolescence:
        await _ref.read(adolescenceMissionsProvider.notifier).swapMission(missionId);
        break;
      case AgeGroup.adults:
        await _ref.read(adultsMissionsProvider.notifier).swapMission(missionId);
        break;
    }
  }

  void updateProgress(String missionId, int increment) {
    final ageGroup = _ref.read(currentUserAgeGroupProvider);

    switch (ageGroup) {
      case AgeGroup.children:
        _ref.read(childrenMissionsProvider.notifier).updateMissionProgress(missionId, increment);
        break;
      case AgeGroup.adolescence:
        _ref.read(adolescenceMissionsProvider.notifier).updateMissionProgress(missionId, increment);
        break;
      case AgeGroup.adults:
        _ref.read(adultsMissionsProvider.notifier).updateMissionProgress(missionId, increment);
        break;
    }
  }

  void trackUserAction(String actionType, Map<String, dynamic> metadata) {
    final ageGroup = _ref.read(currentUserAgeGroupProvider);

    switch (ageGroup) {
      case AgeGroup.children:
        _ref.read(childrenMissionsProvider.notifier).trackUserAction(actionType, metadata);
        break;
      case AgeGroup.adolescence:
        _ref.read(adolescenceMissionsProvider.notifier).trackUserAction(actionType, metadata);
        break;
      case AgeGroup.adults:
        _ref.read(adultsMissionsProvider.notifier).trackUserAction(actionType, metadata);
        break;
    }
  }

  Future<void> generateNewMissions({
    int count = 5,
    String? preferredMode,
    String? preferredCategory,
  }) async {
    final ageGroup = _ref.read(currentUserAgeGroupProvider);

    switch (ageGroup) {
      case AgeGroup.children:
        await _ref.read(childrenMissionsProvider.notifier).generateNewMissions(
          count: count,
          preferredMode: preferredMode,
          preferredCategory: preferredCategory,
        );
        break;
      case AgeGroup.adolescence:
        await _ref.read(adolescenceMissionsProvider.notifier).generateNewMissions(
          count: count,
          preferredMode: preferredMode,
          preferredCategory: preferredCategory,
        );
        break;
      case AgeGroup.adults:
        await _ref.read(adultsMissionsProvider.notifier).generateNewMissions(
          count: count,
          preferredMode: preferredMode,
          preferredCategory: preferredCategory,
        );
        break;
    }
  }
}

// Extension for easy mission tracking throughout your app
extension MissionTracking on WidgetRef {
  void trackMissionAction(String actionType, [Map<String, dynamic>? metadata]) {
    read(missionActionsProvider).trackUserAction(actionType, metadata ?? {});
  }

  // Specific tracking methods for common actions
  void trackCorrectAnswer(String category, String mode) {
    trackMissionAction('question_correct', {
      'category': category,
      'mode': mode,
    });
  }

  void trackStreak(int streakLength, String mode) {
    trackMissionAction('streak_achieved', {
      'streak_length': streakLength,
      'mode': mode,
    });
  }

  void trackComboTriggered(String mode) {
    trackMissionAction('combo_triggered', {'mode': mode});
  }

  void trackAccuracyMaintained(double accuracy, String mode) {
    trackMissionAction('accuracy_maintained', {
      'accuracy': accuracy,
      'mode': mode,
    });
  }

  void trackPerfectRound(String mode) {
    trackMissionAction('perfect_round', {'mode': mode});
  }

  void trackFastAnswer(double timeInSeconds, String mode) {
    trackMissionAction('fast_answer', {
      'time': timeInSeconds,
      'mode': mode,
    });
  }

  void trackSurvivalProgress(int questionsAnswered) {
    trackMissionAction('survival_progress', {
      'questions_answered': questionsAnswered,
    });
  }

  void trackMultiplayerGame(bool won) {
    trackMissionAction('multiplayer_game', {'won': won});
  }
}