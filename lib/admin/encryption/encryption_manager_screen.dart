import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/riverpod_providers.dart';
import '../controllers/encryption_controller.dart';

final encryptionControllerProvider =
ChangeNotifierProvider((ref) => EncryptionController());

enum EncryptionType { aes, fernet }

class EncryptionManagerScreen extends ConsumerStatefulWidget {
  const EncryptionManagerScreen({super.key});

  @override
  ConsumerState<EncryptionManagerScreen> createState() => _EncryptionManagerScreenState();
}

class _EncryptionManagerScreenState extends ConsumerState<EncryptionManagerScreen> {
  final TextEditingController _inputController = TextEditingController();
  EncryptionType _selectedType = EncryptionType.aes;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(encryptionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("🔐 Encryption Manager")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<EncryptionType>(
              value: _selectedType,
              onChanged: (val) {
                setState(() => _selectedType = val!);
              },
              items: EncryptionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type == EncryptionType.aes ? "AES" : "Fernet"),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inputController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter text to encrypt or decrypt',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock),
                  label: const Text("Encrypt"),
                  onPressed: () => _handleEncrypt(controller),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open),
                  label: const Text("Decrypt"),
                  onPressed: () => _handleDecrypt(controller),
                ),
                TextButton(
                  onPressed: () {
                    _inputController.clear();
                    controller.clear();
                  },
                  child: const Text("Clear"),
                )
              ],
            ),
            const Divider(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Output:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            SelectableText(
              controller.lastResult,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _handleEncrypt(EncryptionController controller) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    if (_selectedType == EncryptionType.aes) {
      controller.encryptTextAES(text);
    } else {
      final fernet = ref.watch(fernetControllerProvider.notifier);
      final result = await fernet.encrypt(text);
      controller.setResult(result);
    }
  }

  void _handleDecrypt(EncryptionController controller) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    if (_selectedType == EncryptionType.aes) {
      controller.decryptTextAES(text);
    } else {
      final fernet = ref.watch(fernetControllerProvider.notifier);
      final result = await fernet.decrypt(text);
      controller.setResult(result);
    }
  }
}
