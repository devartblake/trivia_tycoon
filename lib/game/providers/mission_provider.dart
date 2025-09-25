import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/helpers/mission_notification_helper.dart';
import '../models/mission_model.dart';
import '../services/mission_service.dart';

class MissionProvider extends ChangeNotifier {
  final MissionNotificationHelper _notificationHelper = MissionNotificationHelper();
  final MissionService _missionService;
  final String _userId;

  MissionProvider(this._missionService, this._userId);

  // State
  List<UserMission> _missions = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<UserMission>>? _missionSubscription;

  // Getters
  List<UserMission> get missions => _missions;
  List<UserMission> get activeMissions =>
      _missions.where((m) => m.status == MissionStatus.active).toList();
  List<UserMission> get completedMissions =>
      _missions.where((m) => m.status == MissionStatus.completed).toList();
  List<UserMission> get dailyMissions =>
      _missions.where((m) => m.mission.type == MissionType.daily).toList();
  List<UserMission> get weeklyMissions =>
      _missions.where((m) => m.mission.type == MissionType.weekly).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  // Statistics
  int get totalCompletedMissions => completedMissions.length;
  int get totalRewardsEarned => completedMissions
      .fold(0, (sum, mission) => sum + mission.mission.reward);
  double get overallProgress => _missions.isEmpty
      ? 0.0
      : _missions
      .map((m) => m.progressPercentage)
      .reduce((a, b) => a + b) / _missions.length;

  @override
  void dispose() {
    _missionSubscription?.cancel();
    super.dispose();
  }

  // Initialize and start listening to real-time updates
  Future<void> initialize() async {
    await loadMissions();
    _startListening();
  }

  // Load missions once
  Future<void> loadMissions() async {
    _setLoading(true);
    _clearError();

    try {
      _missions = await _missionService.getUserMissions(_userId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Start real-time listening
  void _startListening() {
    _missionSubscription?.cancel();
    _missionSubscription = _missionService.watchUserMissions(_userId).listen(
          (missions) {
        _missions = missions;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  // Swap a mission
  Future<void> swapMission(String userMissionId) async {
    _clearError();

    try {
      final swappedMission = await _missionService.swapMission(userMissionId);

      // Update local state
      final index = _missions.indexWhere((m) => m.id == userMissionId);
      if (index != -1) {
        _missions[index] = swappedMission;
        notifyListeners();
      }

      // Add notification integration
      await _notificationHelper.onMissionSwapped(
        oldMissionId: userMissionId,
        newMissionId: swappedMission.id,
        newMissionTitle: swappedMission.mission.title,
        userId: _userId,
      );
    } catch (e) {
      _setError(e.toString());
      rethrow; // Let the UI handle the error too
    }
  }

  // Update mission progress
  Future<void> updateMissionProgress(String userMissionId, int increment) async {
    _clearError();

    try {
      final updatedMission = await _missionService.updateProgress(userMissionId, increment);

      // Update local state
      final index = _missions.indexWhere((m) => m.id == userMissionId);
      if (index != -1) {
        final oldMission = _missions[index];
        _missions[index] = updatedMission;

        // Check if mission was just completed
        if (updatedMission.isCompleted && !oldMission.isCompleted) {
          _onMissionCompleted(updatedMission);
        }

        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Generate daily missions
  Future<void> generateDailyMissions() async {
    _setLoading(true);
    _clearError();

    try {
      final newMissions = await _missionService.generateDailyMissions(_userId);

      // Add new missions to the list
      _missions.addAll(newMissions);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Track user action (this can be called from anywhere in the app)
  Future<void> trackUserAction(String actionType, Map<String, dynamic> metadata) async {
    try {
      await _missionService.trackUserAction(_userId, actionType, metadata);
      // The real-time listener will automatically update the UI when progress changes
    } catch (e) {
      // Don't show error to user for tracking failures
      debugPrint('Failed to track user action: $e');
    }
  }

  // Get mission by ID
  UserMission? getMissionById(String missionId) {
    try {
      return _missions.firstWhere((m) => m.id == missionId);
    } catch (e) {
      return null;
    }
  }

  // Get missions by type
  List<UserMission> getMissionsByType(MissionType type) {
    return _missions.where((m) => m.mission.type == type).toList();
  }

  // Get missions by status
  List<UserMission> getMissionsByStatus(MissionStatus status) {
    return _missions.where((m) => m.status == status).toList();
  }

  // Check if user can swap any missions
  bool get hasSwappableMissions => _missions.any((m) => m.canSwap);

  // Get missions that expire today
  List<UserMission> get expiringSoonMissions {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _missions.where((m) =>
    m.mission.expiresAt != null &&
        m.mission.expiresAt!.isBefore(tomorrow) &&
        m.status == MissionStatus.active
    ).toList();
  }

  // Refresh missions (pull to refresh)
  Future<void> refresh() async {
    await loadMissions();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _onMissionCompleted(UserMission mission) {
    // Handle mission completion (you can add UI feedback here)
    debugPrint('Mission completed: ${mission.mission.title} (+${mission.mission.reward} rewards)');

    // You could show a snackbar, play a sound, etc.
    // Send notification safely
    _notificationHelper.onMissionCompleted(
      missionId: mission.id,
      missionTitle: mission.mission.title,
      reward: mission.mission.reward,
      userId: _userId,
    );
  }
}

// Extension to make mission filtering easier
extension MissionFilters on List<UserMission> {
  List<UserMission> active() => where((m) => m.status == MissionStatus.active).toList();
  List<UserMission> completed() => where((m) => m.status == MissionStatus.completed).toList();
  List<UserMission> daily() => where((m) => m.mission.type == MissionType.daily).toList();
  List<UserMission> weekly() => where((m) => m.mission.type == MissionType.weekly).toList();
  List<UserMission> canSwap() => where((m) => m.canSwap).toList();
  List<UserMission> expiringSoon() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return where((m) =>
    m.mission.expiresAt != null &&
        m.mission.expiresAt!.isBefore(tomorrow) &&
        m.status == MissionStatus.active
    ).toList();
  }
}