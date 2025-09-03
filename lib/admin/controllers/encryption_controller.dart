import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/core/utils/encryption_utils.dart';

class EncryptionController extends ChangeNotifier {
  String _lastResult = '';
  String get lastResult => _lastResult;

  bool _hasError = false;
  bool get hasError => _hasError;

  /// Encrypt plain text using AES
  void encryptTextAES(String plainText) {
    try {
      _lastResult = EncryptionUtils.encryptAES(plainText);
      _hasError = false;
    } catch (e) {
      _lastResult = 'Encryption failed';
      _hasError = true;
    }
    notifyListeners();
  }

  /// Decrypt encrypted AES text
  void decryptTextAES(String encryptedText) {
    try {
      _lastResult = EncryptionUtils.decryptAES(encryptedText);
      _hasError = false;
    } catch (e) {
      _lastResult = 'Decryption failed';
      _hasError = true;
    }
    notifyListeners();
  }

  /// Set result
  void setResult(String result) {
    _lastResult = result;
    notifyListeners();
  }

  /// Clear result
  void clear() {
    _lastResult = '';
    _hasError = false;
    notifyListeners();
  }

  /// Encrypt file data (bytes)
  Uint8List encryptBytes(Uint8List inputBytes) {
    try {
      final inputStr = String.fromCharCodes(inputBytes);
      final encrypted = EncryptionUtils.encryptAES(inputStr);
      return Uint8List.fromList(encrypted.codeUnits);
    } catch (e) {
      _lastResult = 'File encryption failed';
      _hasError = true;
      notifyListeners();
      return Uint8List(0);
    }
  }

  /// Decrypt file data (bytes)
  Uint8List decryptBytes(Uint8List encryptedBytes) {
    try {
      final encryptedStr = String.fromCharCodes(encryptedBytes);
      final decrypted = EncryptionUtils.decryptAES(encryptedStr);
      return Uint8List.fromList(decrypted.codeUnits);
    } catch (e) {
      _lastResult = 'File decryption failed';
      _hasError = true;
      notifyListeners();
      return Uint8List(0);
    }
  }
}
