import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../game/models/question_model.dart';
import '../../../core/utils/encryption_utils.dart';

class FileImportExportScreen extends StatefulWidget {
  const FileImportExportScreen({super.key});

  @override
  State<FileImportExportScreen> createState() => _FileImportExportScreenState();
}

class _FileImportExportScreenState extends State<FileImportExportScreen> {
  List<QuestionModel> _importedQuestions = [];
  String? _status;

  Future<void> _importFromFile() async {
    setState(() => _status = '📂 Picking file...');
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final file = File(filePath);
      final content = await file.readAsString();

      try {
        final decrypted = EncryptionUtils.decryptAES(content);
        final List decoded = jsonDecode(decrypted);
        final questions = decoded
            .map((e) => QuestionModel.fromJson(e))
            .toList();

        setState(() {
          _importedQuestions = List<QuestionModel>.from(questions);
          _status = '✅ Imported ${questions.length} questions.';
        });
      } catch (e) {
        setState(() => _status = '❌ Failed to import file: $e');
      }
    }
  }

  Future<void> _exportToFile() async {
    setState(() => _status = '🧾 Preparing export...');

    try {
      final data = _importedQuestions.map((q) => q.toJson()).toList();
      final jsonStr = jsonEncode(data);
      final encrypted = EncryptionUtils.encryptAES(jsonStr);

      final outputFile = File(
        '${Directory.systemTemp.path}/exported_questions.json',
      );
      await outputFile.writeAsString(encrypted);

      setState(() {
        _status = '✅ Exported to: ${outputFile.path}';
      });
    } catch (e) {
      setState(() => _status = '❌ Failed to export: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Import/Export')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _importFromFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Import Questions"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _exportToFile,
              icon: const Icon(Icons.download),
              label: const Text("Export Questions"),
            ),
            const SizedBox(height: 20),
            if (_status != null)
              Text(_status!, style: const TextStyle(fontSize: 14)),

            const SizedBox(height: 10),
            Expanded(
              child: _importedQuestions.isEmpty
                  ? const Center(child: Text("No questions imported yet."))
                  : ListView.builder(
                itemCount: _importedQuestions.length,
                itemBuilder: (context, index) {
                  final question = _importedQuestions[index];
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(question.question),
                    subtitle: Text("Category: ${question.category}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}