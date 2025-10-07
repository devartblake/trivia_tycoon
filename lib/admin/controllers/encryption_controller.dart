import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/core/utils/encryption_utils.dart';

/// Controller for managing encryption/decryption operations
class EncryptionController extends ChangeNotifier {
  String _lastResult = '';
  String _lastOperation = '';
  bool _hasError = false;
  bool _isProcessing = false;

  String get lastResult => _lastResult;
  String get lastOperation => _lastOperation;
  bool get hasError => _hasError;
  bool get isProcessing => _isProcessing;

  /// Encrypt plain text using AES
  void encryptTextAES(String plainText) {
    if (plainText.isEmpty) {
      _setError('Input text cannot be empty');
      return;
    }

    _setProcessing(true);

    try {
      _lastResult = EncryptionUtils.encryptAES(plainText);
      _lastOperation = 'AES Encryption';
      _hasError = false;
    } catch (e) {
      _setError('Encryption failed: ${e.toString()}');
    } finally {
      _setProcessing(false);
    }

    notifyListeners();
  }

  /// Decrypt encrypted AES text
  void decryptTextAES(String encryptedText) {
    if (encryptedText.isEmpty) {
      _setError('Input text cannot be empty');
      return;
    }

    _setProcessing(true);

    try {
      _lastResult = EncryptionUtils.decryptAES(encryptedText);
      _lastOperation = 'AES Decryption';
      _hasError = false;
    } catch (e) {
      _setError('Decryption failed: ${e.toString()}');
    } finally {
      _setProcessing(false);
    }

    notifyListeners();
  }

  /// Set result directly (used by external encryption methods)
  void setResult(String result, {String operation = 'Operation'}) {
    _lastResult = result;
    _lastOperation = operation;
    _hasError = false;
    notifyListeners();
  }

  /// Clear all state
  void clear() {
    _lastResult = '';
    _lastOperation = '';
    _hasError = false;
    _isProcessing = false;
    notifyListeners();
  }

  /// Encrypt file data (bytes)
  Uint8List encryptBytes(Uint8List inputBytes) {
    if (inputBytes.isEmpty) {
      _setError('Input data cannot be empty');
      return Uint8List(0);
    }

    _setProcessing(true);

    try {
      final inputStr = String.fromCharCodes(inputBytes);
      final encrypted = EncryptionUtils.encryptAES(inputStr);
      _lastOperation = 'File Encryption';
      _hasError = false;
      _setProcessing(false);
      notifyListeners();
      return Uint8List.fromList(encrypted.codeUnits);
    } catch (e) {
      _setError('File encryption failed: ${e.toString()}');
      _setProcessing(false);
      notifyListeners();
      return Uint8List(0);
    }
  }

  /// Decrypt file data (bytes)
  Uint8List decryptBytes(Uint8List encryptedBytes) {
    if (encryptedBytes.isEmpty) {
      _setError('Input data cannot be empty');
      return Uint8List(0);
    }

    _setProcessing(true);

    try {
      final encryptedStr = String.fromCharCodes(encryptedBytes);
      final decrypted = EncryptionUtils.decryptAES(encryptedStr);
      _lastOperation = 'File Decryption';
      _hasError = false;
      _setProcessing(false);
      notifyListeners();
      return Uint8List.fromList(decrypted.codeUnits);
    } catch (e) {
      _setError('File decryption failed: ${e.toString()}');
      _setProcessing(false);
      notifyListeners();
      return Uint8List(0);
    }
  }

  /// Validate encrypted text format
  bool isValidEncryptedFormat(String text) {
    if (text.isEmpty) return false;
    // Add your validation logic here based on encryption format
    return text.length > 10; // Simple check
  }

  /// Get operation history summary
  Map<String, dynamic> getOperationSummary() {
    return {
      'lastOperation': _lastOperation,
      'hasResult': _lastResult.isNotEmpty,
      'resultLength': _lastResult.length,
      'hasError': _hasError,
      'isProcessing': _isProcessing,
    };
  }

  // Private helper methods
  void _setError(String message) {
    _lastResult = message;
    _hasError = true;
    _isProcessing = false;
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
  }
}
