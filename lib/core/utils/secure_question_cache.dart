import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';
import 'package:trivia_tycoon/core/utils/encryption_utils.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';

class EncryptedQuestionCache {
  static const _cacheBox = 'encrypted_question_cache';
  static final SecureStorage _secureStorage = SecureStorage();

  static Future<void> save(String key, List<QuestionModel> questions) async {
    final jsonList = questions.map((q) => q.toJson()).toList();
    final jsonString = json.encode(jsonList);
    final encrypted = EncryptionUtils.encryptAES(jsonString);

    await _secureStorage.saveEncryptedCache(_cacheBox, key, encrypted);
  }

  static Future<List<QuestionModel>> load(String key) async {
    final encrypted = await _secureStorage.loadEncryptedCache(_cacheBox, key);
    if (encrypted == null) return [];

    try {
      final decrypted = EncryptionUtils.decryptAES(encrypted);
      final List<dynamic> jsonList = json.decode(decrypted);
      return jsonList.map((e) => QuestionModel.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('🔓 Decryption failed: $e');
      }
      return [];
    }
  }

  static Future<void> clear(String key) async {
    await _secureStorage.clearEncryptedCache(_cacheBox, key);
  }
}
