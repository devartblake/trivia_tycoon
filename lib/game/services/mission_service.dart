import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/repositories/mission_repository.dart';
import '../../core/services/notification_service.dart';
import '../models/mission_model.dart';

class MissionService {
  final NotificationService _notificationService = NotificationService();
  final MissionRepository _repository;
  final String _apiBaseUrl;
  final String _apiKey;

  MissionService(
      this._repository, {
        required String apiBaseUrl,
        required String apiKey,
      })  : _apiBaseUrl = apiBaseUrl,
        _apiKey = apiKey;

  // Get user's active missions
  Future<List<UserMission>> getUserMissions(String userId) async {
    try {
      await _repository.cleanupExpiredMissions();
      return await _repository.getUserMissions(userId);
    } catch (e) {
      throw Exception('Failed to get user missions: $e');
    }
  }

  // Stream user missions for real-time updates
  Stream<List<UserMission>> watchUserMissions(String userId) {
    return _repository.watchUserMissions(userId);
  }

  // Swap a mission for a new one
  Future<UserMission> swapMission(String userMissionId) async {
    try {
      // Call FastAPI for any business logic/validation
      await _callFastAPI('/missions/validate-swap', {
        'user_mission_id': userMissionId,
      });

      final swappedMission = await _repository.swapMission(userMissionId);

      // Notify FastAPI about the swap for analytics/rewards
      _callFastAPI('/missions/mission-swapped', {
        'user_mission_id': userMissionId,
        'new_mission_id': swappedMission.mission.id,
      }).catchError((e) {
        // Don't fail the swap if analytics fails
        debugPrint('Analytics call failed: $e');
      });

      return swappedMission;
    } catch (e) {
      throw Exception('Failed to swap mission: $e');
    }
  }

  // Update mission progress
  Future<UserMission> updateProgress(String userMissionId, int increment) async {
    try {
      // Get current progress
      final missions = await _repository.getUserMissions(''); // You'll need to pass userId
      final mission = missions.firstWhere((m) => m.id == userMissionId);

      final newProgress = mission.progress + increment;
      final updatedMission = await _repository.updateMissionProgress(userMissionId, newProgress);

      // If mission completed, call FastAPI for rewards
      if (updatedMission.isCompleted && !mission.isCompleted) {
        await _notificationService.showMissionNotification(
          title: 'Mission Complete! 🎯',
          body: '${updatedMission.mission.title} completed! +${updatedMission.mission.reward} XP earned',
          reward: updatedMission.mission.reward,
          payload: {
            'mission_id': userMissionId,
            'user_id': updatedMission.userId,
          },
        );

        _callFastAPI('/missions/mission-completed', {
          'user_mission_id': userMissionId,
          'user_id': updatedMission.userId,
          'reward_amount': updatedMission.mission.reward,
        }).catchError((e) {
          debugPrint('Reward processing failed: $e');
        });
      }

      return updatedMission;
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  // Generate daily missions for a user
  Future<List<UserMission>> generateDailyMissions(String userId) async {
    try {
      // Call FastAPI to determine which missions to assign based on user behavior
      final response = await _callFastAPI('/missions/generate-daily', {
        'user_id': userId,
      });

      final missionIds = List<String>.from(response['mission_ids']);
      final assignedMissions = <UserMission>[];

      for (final missionId in missionIds) {
        try {
          final assigned = await _repository.assignMissionToUser(userId, missionId);
          assignedMissions.add(assigned);
        } catch (e) {
          debugPrint('Failed to assign mission $missionId: $e');
        }
      }

      if (assignedMissions.isNotEmpty) {
        await _notificationService.showBasicNotification(
          title: 'New Daily Missions Available! 📋',
          body: '${assignedMissions.length} new missions are ready for you',
          payload: {
            'user_id': userId,
            'type': 'daily_missions',
            'count': assignedMissions.length.toString(),
          },
        );
      }

      return assignedMissions;
    } catch (e) {
      throw Exception('Failed to generate daily missions: $e');
    }
  }

  // Track user action that might affect mission progress
  Future<void> trackUserAction(String userId, String actionType, Map<String, dynamic> metadata) async {
    try {
      // Call FastAPI to process the action and determine mission updates
      final response = await _callFastAPI('/missions/track-action', {
        'user_id': userId,
        'action_type': actionType,
        'metadata': metadata,
      });

      // Update mission progress based on API response
      final progressUpdates = response['progress_updates'] as List?;
      if (progressUpdates != null) {
        for (final update in progressUpdates) {
          await _repository.updateMissionProgress(
            update['user_mission_id'],
            update['new_progress'],
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to track user action: $e');
      // Don't throw - tracking shouldn't break the main flow
    }
  }

  // Get mission recommendations
  Future<List<Mission>> getMissionRecommendations(String userId, MissionType type) async {
    try {
      final response = await _callFastAPI('/missions/recommendations', {
        'user_id': userId,
        'mission_type': type.name,
      });

      final missionIds = List<String>.from(response['recommended_missions']);
      final allMissions = await _repository.getAvailableMissions(type);

      return allMissions.where((mission) => missionIds.contains(mission.id)).toList();
    } catch (e) {
      // Fallback to random missions if API fails
      return await _repository.getAvailableMissions(type);
    }
  }

  // Private method to call FastAPI
  Future<Map<String, dynamic>> _callFastAPI(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$_apiBaseUrl$endpoint');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API call failed: ${response.statusCode} - ${response.body}');
    }
  }
}

// Analytics service for tracking mission events
class MissionAnalyticsService {
  final String _apiBaseUrl;
  final String _apiKey;

  MissionAnalyticsService({
    required String apiBaseUrl,
    required String apiKey,
  })  : _apiBaseUrl = apiBaseUrl,
        _apiKey = apiKey;

  Future<void> trackMissionEvent(String eventType, Map<String, dynamic> properties) async {
    try {
      await http.post(
        Uri.parse('$_apiBaseUrl/analytics/track'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'event_type': eventType,
          'properties': properties,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Analytics tracking failed: $e');
    }
  }

  Future<void> trackMissionSwapped(String userId, String oldMissionId, String newMissionId) async {
    await trackMissionEvent('mission_swapped', {
      'user_id': userId,
      'old_mission_id': oldMissionId,
      'new_mission_id': newMissionId,
    });
  }

  Future<void> trackMissionCompleted(String userId, String missionId, int reward) async {
    await trackMissionEvent('mission_completed', {
      'user_id': userId,
      'mission_id': missionId,
      'reward': reward,
    });
  }

  Future<void> trackMissionProgress(String userId, String missionId, int oldProgress, int newProgress) async {
    await trackMissionEvent('mission_progress', {
      'user_id': userId,
      'mission_id': missionId,
      'old_progress': oldProgress,
      'new_progress': newProgress,
    });
  }
}