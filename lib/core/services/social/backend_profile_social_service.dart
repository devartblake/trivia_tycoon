import '../api_service.dart';

class BackendProfileSocialService {
  BackendProfileSocialService(this._apiService);

  final ApiService _apiService;

  Future<List<Map<String, dynamic>>> searchUsers(String handle) async {
    final response = await _apiService.get(
      '/users/search',
      queryParameters: {'handle': handle},
    );

    final rawItems = response['items'] ??
        response['users'] ??
        response['results'] ??
        response['data'] ??
        const <dynamic>[];

    if (rawItems is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getCareerSummary(String userId) {
    return _apiService.get('/users/$userId/career-summary');
  }

  Future<Map<String, dynamic>> getLoadout() {
    return _apiService.get('/users/me/preferences/loadout');
  }

  Future<Map<String, dynamic>> saveLoadout(Map<String, dynamic> loadout) {
    return _apiService.put('/users/me/preferences/loadout', body: loadout);
  }

  Future<Map<String, dynamic>> removeFriend(String friendId) {
    return _apiService.delete(
      '/friends',
      body: {
        // Send both common field names so the client remains compatible with
        // either backend binder shape while alpha contracts settle.
        'friendId': friendId,
        'targetUserId': friendId,
      },
    );
  }
}
