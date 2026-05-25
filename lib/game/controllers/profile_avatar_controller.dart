import 'dart:async' show unawaited;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/avatar_upload_service.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/settings/profile_sync_service.dart';
import 'package:trivia_tycoon/ui_components/depth_card_3d/depth_card.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';

enum AvatarType { image, asset2D, asset3D }

class ProfileAvatarController extends ChangeNotifier {
  XFile? _imageFile;
  String? _avatarPath;
  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();
  DepthCardTheme _depthCardTheme = DepthCardTheme.presets[0];

  final String _profileImageKey = 'profile_image_path';
  final String _avatarPathKey = 'avatar_asset_path';
  final String _themeKey = 'avatar_theme';
  static const String _remoteAvatarKey = 'remote_avatar_url';

  final GeneralKeyValueStorageService keyValueStorage;
  final AppCacheService appCache;
  final AvatarUploadService? uploadService;
  final ProfileSyncService? syncService;

  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _remoteAvatarUrl;
  String? _uploadError;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get remoteAvatarUrl => _remoteAvatarUrl;
  String? get uploadError => _uploadError;

  ProfileAvatarController({
    required this.keyValueStorage,
    required this.appCache,
    this.uploadService,
    this.syncService,
  }) {
    loadProfileImage();
    loadAvatarAsset();
    loadTheme();
    _loadRemoteAvatarUrl();
  }

  // Public Getters
  DepthCardTheme get depthCardTheme => _depthCardTheme;
  XFile? get imageFile => _imageFile;
  File? get avatarFile => _avatarFile;
  String? get avatarPath => _avatarPath;

  @visibleForTesting
  set imageFileForTesting(XFile? file) => _imageFile = file;

  // Load image from gallery or camera with square crop applied
  Future<void> pickImage(ImageSource source) async {
    if (kIsWeb) return;
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    try {
      final cropped = await _cropToSquare(picked.path);
      final savePath = cropped ?? picked.path;
      _imageFile = XFile(savePath);
      await keyValueStorage.setString(_profileImageKey, savePath);
      notifyListeners();
    } catch (e) {
      LogManager.error('Avatar crop failed, using original: $e',
          source: 'ProfileAvatarController');
      _imageFile = picked;
      await keyValueStorage.setString(_profileImageKey, picked.path);
      notifyListeners();
    }

    // Fire-and-forget so the local preview shows immediately.
    if (_imageFile != null) {
      unawaited(_uploadAndSync(_imageFile!));
    }
  }

  /// Retry a previously failed upload using the current [imageFile].
  Future<void> retryUpload() async {
    if (_imageFile == null) return;
    _uploadError = null;
    notifyListeners();
    await _uploadAndSync(_imageFile!);
  }

  Future<void> _uploadAndSync(XFile file) async {
    if (uploadService == null) return;

    _isUploading = true;
    _uploadError = null;
    notifyListeners();

    try {
      final url = await uploadService!.uploadAvatar(
        file: file,
        onProgress: (p) {
          _uploadProgress = p;
          notifyListeners();
        },
      );
      _remoteAvatarUrl = url;
      _uploadProgress = 0.0;
      await keyValueStorage.setString(_remoteAvatarKey, url);
      await syncService?.syncProfileFields(avatar: url);
    } catch (e) {
      _uploadError = e.toString();
      _uploadProgress = 0.0;
      LogManager.error('Avatar upload failed: $e',
          source: 'ProfileAvatarController');
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Crops [sourcePath] to a centred square using the `image` package.
  Future<String?> _cropToSquare(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final w = decoded.width;
    final h = decoded.height;
    final side = w < h ? w : h;
    final offsetX = (w - side) ~/ 2;
    final offsetY = (h - side) ~/ 2;

    final cropped = img.copyCrop(
      decoded,
      x: offsetX,
      y: offsetY,
      width: side,
      height: side,
    );

    final result = img.encodeJpg(cropped, quality: 90);
    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(outPath).writeAsBytes(result);
    return outPath;
  }

  // Load saved image path from Hive
  Future<void> loadProfileImage() async {
    if (kIsWeb) return;
    final path = await keyValueStorage.getString(_profileImageKey);
    if (path != null && File(path).existsSync()) {
      _imageFile = XFile(path);
      notifyListeners();
    }
  }

  // Load saved avatar asset path (2D or 3D)
  Future<void> loadAvatarAsset() async {
    final path = await keyValueStorage.getString(_avatarPathKey);
    if (path != null) {
      _avatarPath = path;
      notifyListeners();
    }
  }

  Future<void> _loadRemoteAvatarUrl() async {
    final url = await keyValueStorage.getString(_remoteAvatarKey);
    if (url != null && url.isNotEmpty) {
      _remoteAvatarUrl = url;
      notifyListeners();
    }
  }

  // Save selected avatar from assets
  Future<void> selectAvatarFromAsset(String assetPath) async {
    if (!kIsWeb) _avatarFile = File(assetPath);
    _avatarPath = assetPath;
    await keyValueStorage.setString(_avatarPathKey, assetPath);
    notifyListeners();
  }

  // Clear selected avatar asset
  Future<void> clearAvatar() async {
    _avatarFile = null;
    _avatarPath = null;
    await appCache.remove(_avatarPathKey);
    notifyListeners();
  }

  // Reset selected avatar asset
  Future<void> resetAvatar() async {
    _avatarPath = null;
    _avatarFile = null;
    await appCache.remove(_avatarPathKey);
    notifyListeners();
  }

  Future<void> setDepthCardTheme(DepthCardTheme theme) async {
    _depthCardTheme = theme;
    await keyValueStorage.setString(_themeKey, theme.name);
    notifyListeners();
  }

  Future<void> loadTheme() async {
    final saved = await keyValueStorage.getString(_themeKey);
    if (saved != null) {
      _depthCardTheme = DepthCardTheme.fromName(saved);
      notifyListeners();
    }
  }

  // Determines if selected asset is 3D (supports .glb and .obj)
  bool get is3DAvatar {
    return _avatarPath != null &&
        (_avatarPath!.endsWith('.glb') || _avatarPath!.endsWith('.obj'));
  }

  // Fallback method for current path to display
  String get effectiveAvatarPath {
    if (_avatarPath != null) return _avatarPath!;
    if (_imageFile != null) return _imageFile!.path;
    return '';
  }

  // Determine avatar type
  AvatarType get avatarType {
    if (is3DAvatar) return AvatarType.asset3D;
    if (_avatarPath != null) return AvatarType.asset2D;
    return AvatarType.image;
  }
}
