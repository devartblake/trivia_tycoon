import 'package:flutter/material.dart';
import '../../../core/utils/encryption_utils.dart';

class EncryptionManagerScreen extends StatefulWidget {
  const EncryptionManagerScreen({super.key});

  @override
  State<EncryptionManagerScreen> createState() => _EncryptionManagerScreenState();
}

class _EncryptionManagerScreenState extends State<EncryptionManagerScreen> {
  final TextEditingController _plainTextController = TextEditingController();
  final TextEditingController _encryptedController = TextEditingController();

  String? _error;

  void _encryptText() {
    try {
      final text = _plainTextController.text;
      final encrypted = EncryptionUtils.encryptAES(text);
      setState(() {
        _encryptedController.text = encrypted;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Encryption failed: $e');
    }
  }

  void _decryptText() {
    try {
      final encrypted = _encryptedController.text;
      final decrypted = EncryptionUtils.decryptAES(encrypted);
      setState(() {
        _plainTextController.text = decrypted;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Decryption failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encryption Manager')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _plainTextController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Plaintext',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock),
                    label: const Text('Encrypt'),
                    onPressed: _encryptText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Decrypt'),
                    onPressed: _decryptText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _encryptedController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Encrypted Text',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _plainTextController.dispose();
    _encryptedController.dispose();
    super.dispose();
  }
}
