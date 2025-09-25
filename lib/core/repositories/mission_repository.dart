import 'package:supabase_flutter/supabase_flutter.dart';
import '../../game/models/mission_model.dart';

abstract class MissionRepository {
  Future<List<UserMission>> getUserMissions(String userId);
  Future<UserMission> swapMission(String userMissionId);
  Future<UserMission> updateMissionProgress(String userMissionId, int newProgress);
  Future<List<Mission>> getAvailableMissions(MissionType? type);
  Future<UserMission> assignMissionToUser(String userId, String missionId);
  Stream<List<UserMission>> watchUserMissions(String userId);
  Future<void> cleanupExpiredMissions(); // Added this missing method
}

class SupabaseMissionRepository implements MissionRepository {
  final SupabaseClient _supabase;

  SupabaseMissionRepository(this._supabase);

  @override
  Future<List<UserMission>> getUserMissions(String userId) async {
    try {
      final response = await _supabase
          .from('user_missions')
          .select('''
            *,
            mission:missions(*)
          ''')
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserMission.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user missions: $e');
    }
  }

  @override
  Stream<List<UserMission>> watchUserMissions(String userId) {
    return _supabase
        .from('user_missions')
        .select('''
          *,
          mission:missions(*)
        ''')
        .eq('user_id', userId)
        .eq('status', 'active')
        .asStream()
        .map((data) => data
        .map((json) => UserMission.fromJson(json))
        .toList());
  }

  @override
  Future<UserMission> swapMission(String userMissionId) async {
    try {
      // First, get the current mission
      final currentMission = await _supabase
          .from('user_missions')
          .select('*, mission:missions(*)')
          .eq('id', userMissionId)
          .single();

      final userMission = UserMission.fromJson(currentMission);

      // Check if user can swap (max swaps, etc.)
      if (!userMission.canSwap) {
        throw Exception('Cannot swap this mission');
      }

      // Get a random new mission of the same type
      final availableMissions = await getAvailableMissions(userMission.mission.type);

      if (availableMissions.isEmpty) {
        throw Exception('No alternative missions available');
      }

      // Filter out the current mission
      final alternatives = availableMissions
          .where((m) => m.id != userMission.mission.id)
          .toList();

      if (alternatives.isEmpty) {
        throw Exception('No alternative missions available');
      }

      // Select random mission
      final newMission = alternatives[DateTime.now().millisecond % alternatives.length];

      // Update the user mission
      final updateData = {
        'mission_id': newMission.id,
        'progress': 0, // Reset progress
        'swap_count': userMission.swapCount + 1,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final updatedResponse = await _supabase
          .from('user_missions')
          .update(updateData)
          .eq('id', userMissionId)
          .select('*, mission:missions(*)')
          .single();

      return UserMission.fromJson(updatedResponse);
    } catch (e) {
      throw Exception('Failed to swap mission: $e');
    }
  }

  @override
  Future<UserMission> updateMissionProgress(String userMissionId, int newProgress) async {
    try {
      // Get current mission to check completion
      final current = await _supabase
          .from('user_missions')
          .select('*, mission:missions(*)')
          .eq('id', userMissionId)
          .single();

      final userMission = UserMission.fromJson(current);
      final isCompleting = newProgress >= userMission.mission.total &&
          userMission.progress < userMission.mission.total;

      final updateData = <String, dynamic>{
        'progress': newProgress,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If completing the mission
      if (isCompleting) {
        updateData['status'] = 'completed';
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase
          .from('user_missions')
          .update(updateData)
          .eq('id', userMissionId)
          .select('*, mission:missions(*)')
          .single();

      // Log progress history
      await _supabase.from('mission_progress_history').insert({
        'user_mission_id': userMissionId,
        'old_progress': userMission.progress,
        'new_progress': newProgress,
        'action_type': 'increment',
      });

      return UserMission.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update mission progress: $e');
    }
  }

  @override
  Future<List<Mission>> getAvailableMissions(MissionType? type) async {
    try {
      var query = _supabase
          .from('missions')
          .select('*')
          .eq('is_active', true);

      if (type != null) {
        query = query.eq('type', type.name);
      }

      final response = await query;

      return (response as List)
          .map((json) => Mission.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch available missions: $e');
    }
  }

  @override
  Future<UserMission> assignMissionToUser(String userId, String missionId) async {
    try {
      // Check if user already has this mission
      final existing = await _supabase
          .from('user_missions')
          .select('id')
          .eq('user_id', userId)
          .eq('mission_id', missionId)
          .eq('status', 'active')
          .maybeSingle();

      if (existing != null) {
        throw Exception('User already has this mission assigned');
      }

      // Get the mission details
      final mission = await _supabase
          .from('missions')
          .select('*')
          .eq('id', missionId)
          .single();

      final missionData = Mission.fromJson(mission);

      // Calculate expiry for daily missions
      DateTime? expiresAt;
      if (missionData.type == MissionType.daily) {
        expiresAt = DateTime.now().add(const Duration(days: 1));
      } else if (missionData.type == MissionType.weekly) {
        expiresAt = DateTime.now().add(const Duration(days: 7));
      }

      final userMissionData = {
        'user_id': userId,
        'mission_id': missionId,
        'progress': 0,
        'status': 'active',
        'expires_at': expiresAt?.toIso8601String(),
      };

      final response = await _supabase
          .from('user_missions')
          .insert(userMissionData)
          .select('*, mission:missions(*)')
          .single();

      return UserMission.fromJson(response);
    } catch (e) {
      throw Exception('Failed to assign mission: $e');
    }
  }

  // Helper method to clean up expired missions
  @override
  Future<void> cleanupExpiredMissions() async {
    try {
      await _supabase
          .from('user_missions')
          .update({'status': 'expired'})
          .lt('expires_at', DateTime.now().toIso8601String())
          .eq('status', 'active');
    } catch (e) {
      throw Exception('Failed to cleanup expired missions: $e');
    }
  }
}