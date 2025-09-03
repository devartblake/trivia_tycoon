import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';
import '../../../game/models/question_model.dart';
import '../../utils/encryption_utils.dart';

class QuizSessionService {
  static const _boxName = 'quiz_sessions';
  static final SecureStorage _secureStorage = SecureStorage();

  static Future<void> saveSession(
    String sessionId,
    List<QuestionModel> questions,
  ) async {
    final json = jsonEncode(questions.map((q) => q.toJson()).toList());
    final encrypted = EncryptionUtils.encryptAES(json);
    await _secureStorage.saveEncryptedCache(_boxName, sessionId, encrypted);
  }

  static Future<List<QuestionModel>> loadSession(String sessionId) async {
    final encrypted = await _secureStorage.loadEncryptedCache(
      _boxName,
      sessionId,
    );
    if (encrypted == null) return [];

    try {
      final decrypted = EncryptionUtils.decryptAES(encrypted);
      final data = jsonDecode(decrypted) as List<dynamic>;
      return data.map((e) => QuestionModel.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to load session: $e');
      }
      return [];
    }
  }

  static Future<void> deleteSession(String sessionId) async {
    await _secureStorage.clearEncryptedCache(_boxName, sessionId);
  }
}
