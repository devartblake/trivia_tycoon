import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/repositories/mission_repository.dart';
import '../data/mission_data_loader.dart';
import '../providers/riverpod_providers.dart';
import '../services/mission_service.dart';

// Hybrid mission system that combines JSON missions with Supabase persistence
class HybridMissionNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final AgeGroup _ageGroup;
  final MissionService? _missionService; // Optional for backend integration
  List<Map<String, dynamic>> _allAvailableMissions = [];
  String? _userId;
  bool _isBackendMode = false;

  HybridMissionNotifier(
      this._ageGroup, {
        MissionService? missionService,
        String? userId,
      })  : _missionService = missionService,
        _userId = userId,
        super([]) {
    _isBackendMode = _missionService != null && _userId != null;
    _initializeMissions();
  }

  Future<void> _initializeMissions() async {
    // Load missions from JSON (always load these for templates)
    _allAvailableMissions = await MissionDataLoader.loadMissionsForAge(_ageGroup);

    if (_isBackendMode) {
      try {
        await _loadFromBackend();
      } catch (e) {
        debugPrint('Backend unavailable, falling back to JSON-only mode: $e');
        _isBackendMode = false;
        await _generateLocalMissions();
      }
    } else {
      await _generateLocalMissions();
    }
  }

  // Load missions from backend (Supabase)
  Future<void> _loadFromBackend() async {
    if (!_isBackendMode) return;

    try {
      final userMissions = await _missionService!.getUserMissions(_userId!);

      if (userMissions.isNotEmpty) {
        // Convert UserMission objects to Map format for UI compatibility
        final missionsAsMap = userMissions.map((userMission) {
          return {
            'id': userMission.id,
            'title': userMission.mission.title,
            'progress': userMission.progress,
            'total': userMission.mission.total,
            'reward': userMission.mission.reward,
            'icon': userMission.mission.icon,
            'badge': userMission.mission.badge,
            'mode': userMission.mission.metadata?['mode'],
            'category': userMission.mission.metadata?['category'],
            'difficulty': userMission.mission.metadata?['difficulty'] ?? 1,
            'tags': userMission.mission.metadata?['tags'] ?? [],
            'status': userMission.status.name,
            'backend_id': userMission.id, // Keep track of backend ID
          };
        }).toList();

        state = missionsAsMap;
      } else {
        // No existing missions, generate new ones
        await generateNewMissions();
      }
    } catch (e) {
      throw Exception('Failed to load from backend: $e');
    }
  }

  // Generate new missions
  Future<void> generateNewMissions({
    int count = 5,
    String? preferredMode,
    String? preferredCategory,
  }) async {
    if (_isBackendMode) {
      try {
        // Use the existing generateDailyMissions method
        final userMissions = await _missionService!.generateDailyMissions(_userId!);

        if (userMissions.isNotEmpty) {
          final missionsAsMap = userMissions.map((userMission) {
            return {
              'id': userMission.id,
              'title': userMission.mission.title,
              'progress': userMission.progress,
              'total': userMission.mission.total,
              'reward': userMission.mission.reward,
              'icon': userMission.mission.icon,
              'badge': userMission.mission.badge,
              'mode': userMission.mission.metadata?['mode'],
              'category': userMission.mission.metadata?['category'],
              'difficulty': userMission.mission.metadata?['difficulty'] ?? 1,
              'tags': userMission.mission.metadata?['tags'] ?? [],
              'status': userMission.status.name,
              'backend_id': userMission.id,
            };
          }).toList();

          state = missionsAsMap;
          return;
        }
      } catch (e) {
        debugPrint('Backend mission generation failed, falling back to local: $e');
        _isBackendMode = false;
      }
    }

    // Local mission generation
    await _generateLocalMissions(
        count: count,
        preferredMode: preferredMode,
        preferredCategory: preferredCategory
    );
  }

  // Generate missions locally (JSON-only mode)
  Future<void> _generateLocalMissions({
    int count = 5,
    String? preferredMode,
    String? preferredCategory,
  }) async {
    final selectedMissions = MissionDataLoader.selectRandomMissions(
      _allAvailableMissions,
      count,
      preferredMode: preferredMode,
      preferredCategory: preferredCategory,
    );

    // Add unique IDs and reset progress
    final missionsWithIds = selectedMissions.map((mission) {
      return {
        ...mission,
        'id': DateTime.now().millisecondsSinceEpoch.toString() +
            Random().nextInt(10000).toString(),
        'progress': 0,
        'status': 'active',
      };
    }).toList();

    state = missionsWithIds;
  }

  // Swap mission
  Future<void> swapMission(String missionId) async {
    if (_isBackendMode) {
      try {
        // Find the mission to get its backend ID
        final mission = state.firstWhere((m) => m['id'] == missionId);
        final backendId = mission['backend_id'] as String?;

        if (backendId != null) {
          await _missionService!.swapMission(backendId);
          // Reload from backend
          await _loadFromBackend();
          return;
        }
      } catch (e) {
        debugPrint('Backend swap failed, falling back to local: $e');
        _isBackendMode = false;
      }
    }

    // Local swap fallback
    await _swapMissionLocally(missionId);
  }

  Future<void> _swapMissionLocally(String missionId) async {
    final currentMissions = [...state];
    final missionIndex = currentMissions.indexWhere((m) => m['id'] == missionId);

    if (missionIndex == -1) return;

    // Get replacement mission
    final currentTitles = currentMissions.map((m) => m['title']).toSet();
    final availableReplacements = _allAvailableMissions
        .where((m) => !currentTitles.contains(m['title']))
        .toList();

    if (availableReplacements.isEmpty) {
      availableReplacements.addAll(_allAvailableMissions);
    }

    availableReplacements.shuffle();
    final replacement = availableReplacements.first;

    final newMission = {
      ...replacement,
      'id': DateTime.now().millisecondsSinceEpoch.toString() +
          Random().nextInt(10000).toString(),
      'progress': 0,
      'status': 'active',
    };

    currentMissions[missionIndex] = newMission;
    state = currentMissions;
  }

  // Update progress
  Future<void> updateMissionProgress(String missionId, int increment) async {
    if (_isBackendMode) {
      try {
        final mission = state.firstWhere((m) => m['id'] == missionId);
        final backendId = mission['backend_id'] as String?;

        if (backendId != null) {
          await _missionService!.updateProgress(backendId, increment);
          // Reload from backend
          await _loadFromBackend();
          return;
        }
      } catch (e) {
        debugPrint('Backend update failed, falling back to local: $e');
        _isBackendMode = false;
      }
    }

    // Local update fallback
    _updateProgressLocally(missionId, increment);
  }

  void _updateProgressLocally(String missionId, int increment) {
    final updatedMissions = state.map((mission) {
      if (mission['id'] == missionId) {
        final newProgress = (mission['progress'] as int) + increment;
        final total = mission['total'] as int;
        final clampedProgress = newProgress.clamp(0, total);

        return {
          ...mission,
          'progress': clampedProgress,
          'status': clampedProgress >= total ? 'completed' : 'active',
        };
      }
      return mission;
    }).toList();

    state = updatedMissions;
  }

  // Track user actions
  void trackUserAction(String actionType, Map<String, dynamic> metadata) {
    if (_isBackendMode) {
      // Try backend tracking (async, don't wait)
      _missionService!.trackUserAction(_userId!, actionType, metadata).catchError((e) {
        debugPrint('Backend tracking failed: $e');
      });
    }

    // Always do local tracking for immediate UI feedback
    _trackActionLocally(actionType, metadata);
  }

  void _trackActionLocally(String actionType, Map<String, dynamic> metadata) {
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
        if (mission['mode'] == null || mission['mode'] == mode) {
          shouldUpdate = true;
        }
      }

      if (shouldUpdate) {
        final newProgress = (mission['progress'] as int) + increment;
        final total = mission['total'] as int;
        final clampedProgress = newProgress.clamp(0, total);

        return {
          ...mission,
          'progress': clampedProgress,
          'status': clampedProgress >= total ? 'completed' : 'active',
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
        final total = mission['total'] as int;
        final clampedProgress = newProgress.clamp(0, total);

        return {
          ...mission,
          'progress': clampedProgress,
          'status': clampedProgress >= total ? 'completed' : 'active',
        };
      }
      return mission;
    }).toList();

    state = updatedMissions;
  }
}

// Updated providers for hybrid system
final missionRepositoryProvider = Provider<MissionRepository?>((ref) {
  // Return null if you want JSON-only mode
  // Return SupabaseMissionRepository(Supabase.instance.client) for backend integration
  try {
    return SupabaseMissionRepository(Supabase.instance.client);
  } catch (e) {
    debugPrint('Supabase not available, using JSON-only mode');
    return null;
  }
});

final missionServiceProvider = Provider<MissionService?>((ref) {
  final repository = ref.watch(missionRepositoryProvider);
  if (repository == null) return null;

  return MissionService(
    repository,
    apiBaseUrl: 'https://your-fastapi-url.com/api/v1',
    apiKey: 'your-api-key',
  );
});

final currentUserIdProvider = Provider<String?>((ref) {
  // Return user ID if available, null for offline mode
  return 'current-user-id'; // Replace with actual user ID logic
});

// Hybrid mission providers
final hybridMissionsProvider = StateNotifierProvider.family<HybridMissionNotifier, List<Map<String, dynamic>>, AgeGroup>((ref, ageGroup) {
  final missionService = ref.watch(missionServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  return HybridMissionNotifier(
    ageGroup,
    missionService: missionService,
    userId: userId,
  );
});

// Current user missions based on age
final liveMissionsProvider = StateNotifierProvider<HybridMissionNotifier, List<Map<String, dynamic>>>((ref) {
  final ageGroup = ref.watch(currentUserAgeGroupProvider);
  return ref.watch(hybridMissionsProvider(ageGroup).notifier);
});

// Updated mission actions for hybrid system
final missionActionsProvider = Provider<HybridMissionActions>((ref) {
  return HybridMissionActions(ref);
});

class HybridMissionActions {
  final Ref _ref;

  HybridMissionActions(this._ref);

  Future<void> swapMission(String missionId) async {
    await _ref.read(liveMissionsProvider.notifier).swapMission(missionId);
  }

  Future<void> updateProgress(String missionId, int increment) async {
    await _ref.read(liveMissionsProvider.notifier).updateMissionProgress(missionId, increment);
  }

  void trackUserAction(String actionType, Map<String, dynamic> metadata) {
    _ref.read(liveMissionsProvider.notifier).trackUserAction(actionType, metadata);
  }

  Future<void> generateNewMissions({
    int count = 5,
    String? preferredMode,
    String? preferredCategory,
  }) async {
    await _ref.read(liveMissionsProvider.notifier).generateNewMissions(
      count: count,
      preferredMode: preferredMode,
      preferredCategory: preferredCategory,
    );
  }
}