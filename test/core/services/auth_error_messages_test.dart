import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/services/auth_api_client.dart';
import 'package:synaptix/core/services/auth_error_messages.dart';

void main() {
  group('AuthErrorMessages', () {
    test('maps login 401 to credential error copy', () {
      final message = AuthErrorMessages.getLoginErrorMessage(
        const AuthApiException(
          message: 'Invalid credentials',
          path: '/auth/login',
          method: 'POST',
          statusCode: 401,
        ),
      );

      expect(
        message,
        'Invalid email or password. Please check your credentials and try again.',
      );
    });

    test('maps login 403 to permission error copy', () {
      final message = AuthErrorMessages.getLoginErrorMessage(
        const AuthApiException(
          message: 'Forbidden',
          path: '/auth/login',
          method: 'POST',
          statusCode: 403,
        ),
      );

      expect(message, 'You don\'t have permission to perform this action.');
    });

    test('maps login 422 validation body to a validation message', () {
      final message = AuthErrorMessages.getLoginErrorMessage(
        const AuthApiException(
          message: 'Validation failed',
          path: '/auth/login',
          method: 'POST',
          statusCode: 422,
          responseBody: '{"error":{"code":"VALIDATION_ERROR"}}',
        ),
      );

      expect(message, 'Please check your input and try again.');
    });

    test('maps network timeout to retry copy', () {
      final message = AuthErrorMessages.getLoginErrorMessage(
        TimeoutException('request timeout'),
      );

      expect(
        message,
        'Request timed out. Please check your connection and try again.',
      );
    });

    test('maps signup validation and existing-account errors', () {
      expect(
        AuthErrorMessages.getSignupErrorMessage(
          '409 email already registered',
        ),
        'An account with this email already exists. Please log in instead.',
      );
      expect(
        AuthErrorMessages.getSignupErrorMessage(
          'Password length must be at least 8 characters',
        ),
        'Password must be at least 8 characters long.',
      );
      expect(
        AuthErrorMessages.getSignupErrorMessage('Email is invalid'),
        'Please enter a valid email address.',
      );
    });
  });
}
