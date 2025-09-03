import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/hive_providers.dart';
import '../../core/services/encryption/fernet_service.dart';

class FernetController extends AsyncNotifier<FernetService> {
  @override
  Future<FernetService> build() async {
    final storage = ref.read(secureStorageProvider);
    return await FernetService.initialize(storage);
  }

  Future<String> encrypt(String input) async {
    final service = state.valueOrNull ?? await future;
    return await service.encrypt(input);
  }

  Future<String> decrypt(String token) async {
    final service = state.valueOrNull ?? await future;
    return await service.decrypt(token);
  }
}
