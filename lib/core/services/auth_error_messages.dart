import 'package:http/http.dart' as http;

/// User-friendly error messages for common API errors
class AuthErrorMessages {
  /// Convert exception to user-friendly message
  static String getUserFriendlyMessage(dynamic error) {
    // Network/Connection errors — checked by type name to stay dart:io-free on web.
    final typeName = error.runtimeType.toString();
    if (typeName == 'SocketException' ||
        error.toString().startsWith('SocketException:')) {
      return 'Cannot connect to server. Please check your internet connection.';
    }

    if (typeName == 'HttpException' ||
        error.toString().startsWith('HttpException:')) {
      return 'Network error occurred. Please try again.';
    }

    if (error is FormatException) {
      return 'Received invalid data from server. Please try again.';
    }

    // Timeout errors
    if (error.toString().contains('TimeoutException') ||
        error.toString().contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // HTTP Response errors
    if (error is http.Response) {
      return _getHttpErrorMessage(error);
    }

    // String errors with status codes
    final errorStr = error.toString();

    // Authentication errors (401)
    if (errorStr.contains('401') ||
        errorStr.contains('Unauthorized') ||
        errorStr.contains('Invalid credentials')) {
      return 'Invalid email or password. Please try again.';
    }

    // Forbidden errors (403)
    if (errorStr.contains('403') || errorStr.contains('Forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }

    // Not found errors (404)
    if (errorStr.contains('404') || errorStr.contains('Not Found')) {
      return 'The requested resource was not found.';
    }

    // Conflict errors (409) - usually email already exists
    if (errorStr.contains('409') ||
        errorStr.contains('Conflict') ||
        errorStr.contains('already exists') ||
        errorStr.contains('already registered')) {
      return 'An account with this email already exists.';
    }

    // Validation errors (400)
    if (errorStr.contains('400') || errorStr.contains('Bad Request')) {
      // Try to extract specific validation message
      if (errorStr.contains('Email')) {
        return 'Please enter a valid email address.';
      }
      if (errorStr.contains('Password')) {
        return 'Password does not meet requirements.';
      }
      return 'Please check your input and try again.';
    }

    // Server errors (500)
    if (errorStr.contains('500') ||
        errorStr.contains('Internal Server Error') ||
        errorStr.contains('Server Error')) {
      return 'Server error occurred. Please try again later.';
    }

    // Service unavailable (503)
    if (errorStr.contains('503') || errorStr.contains('Service Unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    }

    // Connection refused
    if (errorStr.contains('Connection refused')) {
      return 'Cannot connect to server. Please check if the server is running.';
    }

    // SSL/Certificate errors
    if (errorStr.contains('CERTIFICATE') ||
        errorStr.contains('SSL') ||
        errorStr.contains('HandshakeException')) {
      return 'Secure connection failed. Please check your network settings.';
    }

    // Default fallback
    return 'An error occurred. Please try again.';
  }

  /// Get message for HTTP response error
  static String _getHttpErrorMessage(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Invalid email or password.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'An account with this email already exists.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server error. Please try again later.';
      default:
        return 'An error occurred (${response.statusCode}). Please try again.';
    }
  }

  /// Specific messages for auth operations
  static String getLoginErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('401') || errorStr.contains('Invalid credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    if (errorStr.contains('locked') || errorStr.contains('disabled')) {
      return 'Your account has been locked. Please contact support.';
    }

    if (errorStr.contains('verified') || errorStr.contains('verification')) {
      return 'Please verify your email address before logging in.';
    }

    return getUserFriendlyMessage(error);
  }

  static String getSignupErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('409') ||
        errorStr.contains('already exists') ||
        errorStr.contains('already registered')) {
      return 'An account with this email already exists. Please log in instead.';
    }

    if (errorStr.contains('Email')) {
      return 'Please enter a valid email address.';
    }

    if (errorStr.contains('Password')) {
      if (errorStr.contains('weak') || errorStr.contains('strength')) {
        return 'Password is too weak. Please use a stronger password.';
      }
      if (errorStr.contains('length') || errorStr.contains('characters')) {
        return 'Password must be at least 8 characters long.';
      }
      return 'Password does not meet requirements. Please use at least 8 characters.';
    }

    return getUserFriendlyMessage(error);
  }

  static String getTokenRefreshErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('401') || errorStr.contains('Invalid')) {
      return 'Your session has expired. Please log in again.';
    }

    return 'Session refresh failed. Please log in again.';
  }
}

/// Extension for easy error message retrieval
extension ErrorMessageExtension on Exception {
  String toUserFriendlyMessage() {
    return AuthErrorMessages.getUserFriendlyMessage(this);
  }

  String toLoginErrorMessage() {
    return AuthErrorMessages.getLoginErrorMessage(this);
  }

  String toSignupErrorMessage() {
    return AuthErrorMessages.getSignupErrorMessage(this);
  }
}