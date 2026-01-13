import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});
