import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A class to manage and provide environment variables from a .env file.
/// This ensures that sensitive keys and configuration-specific URLs are not
/// hardcoded in the application source code.
class Env {
  /// Supabase Variables
  static String? _supabaseUrl;
  static String? _supabaseAnonKey;

  /// API Base URL
  static String? _apiBaseUrl;

  /// Getter for Supabase URL
  static String get supabaseUrl {
    assert(_supabaseUrl != null, 'SUPABASE_URL is not loaded from .env');
    return _supabaseUrl!;
  }

  /// Getter for Supabase Anon Key
  static String get supabaseAnonKey {
    assert(_supabaseAnonKey != null, 'SUPABASE_ANON_KEY is not loaded from .env');
    return _supabaseAnonKey!;
  }

  /// Getter for the backend API Base URL.
  static String get apiBaseUrl {
    assert(_apiBaseUrl != null, 'API_BASE_URL is not loaded from .env');
    return _apiBaseUrl!;
  }

  /// Loads all environment variables from the .env file into memory.
  /// This must be called once during app initialization before any services
  /// that rely on these variables are created.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");

      // Load variables from the environment
      _supabaseUrl = dotenv.env['SUPABASE_URL'];
      _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
      _apiBaseUrl = dotenv.env['API_BASE_URL'];

      // Perform checks to ensure essential variables are present
      if (_supabaseUrl == null || _supabaseAnonKey == null || _apiBaseUrl == null) {
        debugPrint('''
        --------------------------------------------------------------------
        ERROR: One or more environment variables not found in .env file.
        Please ensure your .env file is in the root of your project.
        SUPABASE_URL: $_supabaseUrl
        SUPABASE_ANON_KEY: $_supabaseAnonKey
        API_BASE_URL: $_apiBaseUrl
        --------------------------------------------------------------------
        ''');
        // In a production app, you might throw an exception here.
        throw Exception('Required environment variables are missing.');
      }
    } catch (e) {
      debugPrint('Error loading .env file: $e');
      rethrow;
    }
  }
}
