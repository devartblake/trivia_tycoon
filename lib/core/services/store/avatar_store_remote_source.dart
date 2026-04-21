import '../../../game/models/avatar_package_models.dart';
import '../../../game/services/avatar_package_service.dart';
import '../api_service.dart';

/// Implements [AvatarPackageRemoteSource] by fetching avatar items from
/// GET /store/catalog?category=avatar and mapping them to [AvatarPackageMetadata].
///
/// The archiveUrl is intentionally left null here — it is filled on-demand
/// by [AvatarAssetService.getAvatarAsset] when the player taps Install.
class AvatarStoreRemoteSource implements AvatarPackageRemoteSource {
  final ApiService _apiService;

  AvatarStoreRemoteSource(this._apiService);

  @override
  Future<List<AvatarPackageMetadata>> fetchPackages() async {
    final response = await _apiService.get(
      '/store/catalog',
      queryParameters: <String, dynamic>{'category': 'avatar'},
    );

    final rawItems =
        response['items'] as List<dynamic>? ?? const <dynamic>[];

    return rawItems
        .whereType<Map>()
        .map((raw) {
          final json = Map<String, dynamic>.from(raw);
          final id = (json['sku'] ?? json['id'] ?? '').toString();
          if (id.isEmpty) return null;
          return AvatarPackageMetadata(
            id: id,
            name: (json['name'] ?? '').toString(),
            version: (json['version'] ?? '1.0.0').toString(),
            thumbnailUrl: json['thumbnailUrl']?.toString(),
            archiveUrl: null,
            render: const AvatarPackageRenderHints(
              kind: AvatarPackageType.depthCard,
            ),
          );
        })
        .whereType<AvatarPackageMetadata>()
        .toList();
  }
}
