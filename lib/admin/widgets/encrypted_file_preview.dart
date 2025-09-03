import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../admin/controllers/encryption_controller.dart';

class EncryptedFilePreview extends StatefulWidget {
  const EncryptedFilePreview({super.key});


  @override
  State<EncryptedFilePreview> createState() => _EncryptedFilePreviewState();
}

class _EncryptedFilePreviewState extends State<EncryptedFilePreview> {
  String? _decryptedContent;
  String? _fileName;

  Future<void> _pickAndDecryptFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['enc']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final data = await file.readAsBytes();

      final controller = EncryptionController();
      final decrypted = controller.decryptBytes(data);

      setState(() {
        _fileName = file.uri.pathSegments.last;
        _decryptedContent = String.fromCharCodes(decrypted);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔐 Encrypted File Preview')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickAndDecryptFile,
              icon: const Icon(Icons.lock_open),
              label: const Text("Select & Decrypt File"),
            ),
            const SizedBox(height: 20),
            if (_fileName != null)
              Text("📂 File: $_fileName", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _decryptedContent ?? "No file selected.",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
