import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/repositories/mission_repository.dart';
import '../../core/services/notification_service.dart';
import '../models/mission_model.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class MissionService {
  final NotificationService _notificationService = NotificationService();
  final MissionRepository _repository;

  final String _apiBaseUrl;

  /// NOTE:
  /// This is currently treated as an auth token for your backend.
  /// If you're still using an "API key" temporarily, this header will still work.
  /// Later, swap this to your real JWT access token.
  final String _authToken;

  MissionService(
      this._repository, {
        required String apiBaseUrl,
        required String apiKey,
      })  : _apiBaseUrl = apiBaseUrl,
        _authToken = apiKey;

  // ----------------------------
  // Read user's active missions
  // ----------------------------
  Future<List<UserMission>> getUserMissions(String userId) async {
    try {
      await _repository.cleanupExpiredMissions();
      return await _repository.getUserMissions(userId);
    } catch (e) {
      throw Exception('Failed to get user missions: $e');
    }
  }

  // ----------------------------
  // Stream user missions updates
  // ----------------------------
  Stream<List<UserMission>> watchUserMissions(String userId) {
    return _repository.watchUserMissions(userId);
  }

  // ----------------------------
  // Swap a mission for a new one
  // ----------------------------
  Future<UserMission> swapMission(String userMissionId) async {
    try {
      // Optional validation/business rules hook
      await _callFastAPI('/missions/validate-swap', {
        'user_mission_id': userMissionId,
      });

      final swappedMission = await _repository.swapMission(userMissionId);

      // Non-fatal analytics hook
      _callFastAPI('/missions/mission-swapped', {
        'user_mission_id': userMissionId,
        'new_mission_id': swappedMission.mission.id,
      }).catchError((e) {
        LogManager.debug('Analytics call failed: $e');
      });

      return swappedMission;
    } catch (e) {
      throw Exception('Failed to swap mission: $e');
    }
  }

  // ----------------------------
  // Update mission progress
  // ----------------------------
  ///
  /// IMPORTANT FIX:
  /// Your old code tried: `_repository.getUserMissions('')` which breaks correctness.
  ///
  /// To avoid breaking callers, we keep the same positional signature,
  /// but require `userId:` as a named parameter for correctness.
  Future<UserMission> updateProgress(
      String userMissionId,
      int increment, {
        required String userId,
      }) async {
    try {
      // Get current mission state for the user
      final missions = await _repository.getUserMissions(userId);
      final mission = missions.firstWhere((m) => m.id == userMissionId);

      final newProgress = mission.progress + increment;

      final updatedMission =
      await _repository.updateMissionProgress(userMissionId, newProgress);

      // If mission just completed, show notification + call backend hooks
      if (updatedMission.isCompleted && !mission.isCompleted) {
        await _notificationService.showMissionNotification(
          title: 'Mission Complete! 🎯',
          body:
          '${updatedMission.mission.title} completed! +${updatedMission.mission.rewardXp} XP earned',
          reward: updatedMission.mission.rewardXp,
          payload: {
            'mission_id': userMissionId,
            'user_id': updatedMission.userId,
          },
        );

        _callFastAPI('/missions/mission-completed', {
          'user_mission_id': userMissionId,
          'user_id': updatedMission.userId,
          'reward_amount': updatedMission.mission.rewardXp,
        }).catchError((e) {
          LogManager.debug('Reward processing failed: $e');
        });
      }

      return updatedMission;
    } catch (e) {
      throw Exception('Failed to update progress: $e');
    }
  }

  // ----------------------------
  // Generate daily missions
  // ----------------------------
  Future<List<UserMission>> generateDailyMissions(String userId) async {
    try {
      // Backend decides mission IDs based on behavior/segment
      final response = await _callFastAPI('/missions/generate-daily', {
        'user_id': userId,
      });

      final missionIds = List<String>.from(response['mission_ids'] ?? const []);
      final assignedMissions = <UserMission>[];

      for (final missionId in missionIds) {
        try {
          final assigned =
          await _repository.assignMissionToUser(userId, missionId);
          assignedMissions.add(assigned);
        } catch (e) {
          LogManager.debug('Failed to assign mission $missionId: $e');
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

  // ----------------------------
  // Track user action
  // ----------------------------
  Future<void> trackUserAction(
      String userId,
      String actionType,
      Map<String, dynamic> metadata,
      ) async {
    try {
      final response = await _callFastAPI('/missions/track-action', {
        'user_id': userId,
        'action_type': actionType,
        'metadata': metadata,
      });

      final progressUpdates = response['progress_updates'] as List?;
      if (progressUpdates != null) {
        for (final update in progressUpdates) {
          await _repository.updateMissionProgress(
            update['user_mission_id'] as String,
            update['new_progress'] as int,
          );
        }
      }
    } catch (e) {
      LogManager.debug('Failed to track user action: $e');
      // Tracking should never break gameplay
    }
  }

  // ----------------------------
  // Mission recommendations
  // ----------------------------
  Future<List<Mission>> getMissionRecommendations(
      String userId,
      MissionType type,
      ) async {
    try {
      final response = await _callFastAPI('/missions/recommendations', {
        'user_id': userId,
        'mission_type': type.name,
      });

      final recommendedIds =
      List<String>.from(response['recommended_missions'] ?? const []);
      final allMissions = await _repository.getAvailableMissions(type);

      // Keep ordering stable based on server list
      final byId = {for (final m in allMissions) m.id: m};
      return recommendedIds.map((id) => byId[id]).whereType<Mission>().toList();
    } catch (e) {
      // Fallback: local/random list
      return await _repository.getAvailableMissions(type);
    }
  }

  // ----------------------------
  // Backend helper
  // ----------------------------
  Future<Map<String, dynamic>> _callFastAPI(
      String endpoint,
      Map<String, dynamic> data,
      ) async {
    final url = Uri.parse('$_apiBaseUrl$endpoint');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // If this is a JWT: Bearer <access_token>
        // If this is a temp API key: still works as long as backend accepts it.
        'Authorization': 'Bearer $_authToken',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.trim();
      if (body.isEmpty) return <String, dynamic>{};
      return jsonDecode(body) as Map<String, dynamic>;
    }

    throw Exception(
      'API call failed: ${response.statusCode} - ${response.body}',
    );
  }
}
