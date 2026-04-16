import '../dto/learning_dto.dart';
import '../services/api_service.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

abstract class LearningRepository {
  Future<List<ModuleDto>> getModules({
    String? playerId,
    String? category,
    int? difficulty,
  });

  Future<ModuleDto> getModule(String moduleId);

  Future<List<LessonDto>> getLessons(String moduleId);

  Future<ModuleCompleteResponseDto> completeModule(
    String moduleId,
    String playerId,
  );
}

// ---------------------------------------------------------------------------
// API implementation
// ---------------------------------------------------------------------------

class ApiLearningRepository implements LearningRepository {
  final ApiService _api;

  ApiLearningRepository(this._api);

  @override
  Future<List<ModuleDto>> getModules({
    String? playerId,
    String? category,
    int? difficulty,
  }) async {
    final queryParameters = <String, dynamic>{
      if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
      if (category != null && category.isNotEmpty) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
    };

    final raw = await _api.getList(
      '/modules',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return raw.map(ModuleDto.fromJson).toList(growable: false);
  }

  @override
  Future<ModuleDto> getModule(String moduleId) async {
    final raw = await _api.get('/modules/$moduleId');
    return ModuleDto.fromJson(raw);
  }

  @override
  Future<List<LessonDto>> getLessons(String moduleId) async {
    final raw = await _api.getList('/modules/$moduleId/lessons');
    return raw.map(LessonDto.fromJson).toList(growable: false);
  }

  @override
  Future<ModuleCompleteResponseDto> completeModule(
    String moduleId,
    String playerId,
  ) async {
    // POST with no body; playerId is a query param per the API contract.
    final raw = await _api.post(
      '/modules/$moduleId/complete?playerId=$playerId',
      body: const {},
    );
    return ModuleCompleteResponseDto.fromJson(raw);
  }
}
