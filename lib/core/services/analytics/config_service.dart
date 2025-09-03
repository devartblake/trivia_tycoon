import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import '../storage/config_storage_service.dart';

class ConfigService extends ChangeNotifier {
  /// Singleton instance
  static final ConfigService _instance = ConfigService._internal();
  static ConfigService get instance => _instance;
  Timer? _syncTimer;

  /// Private constructor
  ConfigService._internal();

  /// Static configuration Map (updated)
  static Map<String, dynamic> _config = _defaultConfig;
  static const String _remoteConfigKey = "remote_config";

  /// Internal variables
  late ApiService _apiService;
  late ConfigStorageService _configStorage;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool _isGalleryActive = false;

  /// Constants for retry logic
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(seconds: 2);

  /// Inject dependencies from ServiceManager
  void initServices(ServiceManager manager) {
    _configStorage = manager.configStorageService;
    _apiService = manager.apiService;
  }

  void startAutoSync({Duration interval = const Duration(minutes: 30)}) {
    _syncTimer?.cancel(); // clear previous
    _syncTimer = Timer.periodic(interval, (_) async {
      if (kDebugMode) print("🔁 Auto-syncing remote config...");
      await refreshConfig();
    });
  }

  void disposeAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Accessor methods
  ApiService get apiService => _apiService;
  bool get isGalleryActive => _isGalleryActive;

  /// Static helper methods for assets
  static String? getPackage(String value) =>
      ConfigService.instance.isGalleryActive ? value : null;

  static String getBundle(String value) => "packages/$value";

  static String getAssetPath(String assetPath) =>
      ConfigService.instance.isGalleryActive
          ? "packages/${getBundle(assetPath)}"
          : assetPath;

  /// Gets encryption key from config file.
  static String getEncryptionKey() {
    if (!_instance._isLoaded) {
      throw Exception(
        "ConfigService not initialized. Call `await ConfigService.loadConfig()` first.",
      );
    }
    return _config['ENCRYPTION_KEY'] ?? "default_key_32charslong!";
  }

  /// Load configuration (must call on app startup)
  Future<void> loadConfig() async {
    if (_isLoaded) return;

    /// Step 1: Load local config
    await _loadLocalConfig();
    if (kDebugMode) print("✅ Local config loaded.");

    /// Step 2: Fetch remote config with retry logic
    await _fetchRemoteConfig();

    /// Step 3: Update ApiService base URL
    _apiService = ApiService(baseUrl: apiBaseUrl);

    _isLoaded = true;
    notifyListeners();

    if (kDebugMode) print("🚀 ConfigService fully initialized.");
  }

  /// Load local config from JSON asset
  Future<void> _loadLocalConfig() async {
    try {
      final jsonString =
      await rootBundle.loadString('assets/config/config.json');
      _config = json.decode(jsonString);
      _isGalleryActive = _config["GALLERY_MODE"] ?? false;
    } catch (e) {
      if (kDebugMode) {
        print("⚠️ Local config load failed, using defaults: $e");
      }
      _config = _defaultConfig;
    }
  }

  /// Fetch remote config with retries and exponential backoff
  Future<void> _fetchRemoteConfig() async {
    int attempt = 0;
    Duration delay = _initialDelay;

    // Load cached config first
    final cachedConfig = await _configStorage.getConfig(_remoteConfigKey);
    if (cachedConfig != null) {
      _config = {..._config, ...json.decode(cachedConfig)};
      _isGalleryActive = _config["GALLERY_MODE"] ?? false;
      if (kDebugMode) print("💾 Loaded cached remote config.");
    }

    while (attempt < _maxRetries) {
      try {
        final response = await http.get(
          Uri.parse("${_getBaseUrlSafely()}/config"),
        );

        if (response.statusCode == 200) {
          final remoteConfig = json.decode(response.body);
          _config = {..._config, ...remoteConfig};
          _isGalleryActive = _config["GALLERY_MODE"] ?? false;

          await _configStorage.saveConfig(_remoteConfigKey, json.encode(remoteConfig));
          notifyListeners();

          if (kDebugMode) {
            print("✅ Remote config successfully fetched: $remoteConfig");
          }
          return;
        } else {
          throw Exception(
            "Server responded with status: ${response.statusCode}",
          );
        }
      } catch (e) {
        attempt++;
        if (kDebugMode) {
          print("⚠️ Attempt $attempt of $_maxRetries failed: $e");
        }
        if (attempt < _maxRetries) {
          await Future.delayed(delay);
          delay *= 2;
        } else {
          if (kDebugMode) {
            print("❌ Remote config fetch failed after $_maxRetries attempts.");
          }
        }
      }
    }
  }

  /// Safely get base URL before fully loaded
  String _getBaseUrlSafely() {
    switch (_config['APP_ENV'] ?? 'prod') {
      case 'dev':
        return _config['API_BASE_URL_DEV'] ?? _defaultBaseUrl;
      case 'staging':
        return _config['API_BASE_URL_STAGING'] ?? _defaultBaseUrl;
      case 'prod':
      default:
        return _config['API_BASE_URL_PROD'] ?? _defaultBaseUrl;
    }
  }

  /// Expose API Base URL
  String get apiBaseUrl {
    if (!_isLoaded) {
      if (kDebugMode) {
        print("⚠️ Warning: apiBaseUrl accessed before initialization.");
      }
      return _getBaseUrlSafely();
    }
    return _getBaseUrlSafely();
  }

  /// Check if logging is enabled
  static bool get enableLogging {
    final val = _config['ENABLE_LOGGING'];
    return val is bool ? val : (val?.toString().toLowerCase() == 'true');
  }

  /// Refresh remote configuration manually
  Future<void> refreshConfig() async => _fetchRemoteConfig();

  /// Default config fallback
  static const Map<String, dynamic> _defaultConfig = {
    "APP_ENV": "prod",
    "API_BASE_URL_PROD": "https://fallback-api.com",
    "ENABLE_LOGGING": "false",
    "GALLERY_MODE": false,
  };

  /// Default fallback URL
  static const String _defaultBaseUrl = "https://fallback-api.com";
}
