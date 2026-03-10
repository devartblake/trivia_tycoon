import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/models/question_model.dart';
import '../../../core/utils/encryption_utils.dart';
import '../../../core/services/api_service.dart';
import 'question_ingestion_service.dart';

class FileImportExportScreen extends ConsumerStatefulWidget {
  const FileImportExportScreen({super.key});

  @override
  ConsumerState<FileImportExportScreen> createState() => _FileImportExportScreenState();
}

class _FileImportExportScreenState extends ConsumerState<FileImportExportScreen> {
  List<QuestionModel> _importedQuestions = [];
  String? _status;
  bool _isProcessing = false;
  final TextEditingController _datasetNameController = TextEditingController(text: 'community_pack');
  bool _publishAfterImport = false;

  Future<void> _importFromFile() async {
    setState(() {
      _status = 'Picking file...';
      _isProcessing = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final content = await file.readAsString();

        try {
          final decrypted = EncryptionUtils.decryptAES(content);
          final List decoded = jsonDecode(decrypted);
          final questions = decoded.map((e) => QuestionModel.fromJson(e)).toList();

          setState(() {
            _importedQuestions = List<QuestionModel>.from(questions);
            _status = 'Successfully imported ${questions.length} questions';
            _isProcessing = false;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Imported ${questions.length} questions'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } catch (e) {
          setState(() {
            _status = 'Failed to import file: $e';
            _isProcessing = false;
          });
        }
      } else {
        setState(() {
          _status = null;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _exportToFile() async {
    if (_importedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('No questions to export'),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _status = 'Preparing export...';
      _isProcessing = true;
    });

    try {
      final data = _importedQuestions.map((q) => q.toJson()).toList();
      final jsonStr = jsonEncode(data);
      final encrypted = EncryptionUtils.encryptAES(jsonStr);

      final outputFile = File('${Directory.systemTemp.path}/exported_questions.json');
      await outputFile.writeAsString(encrypted);

      setState(() {
        _status = 'Successfully exported to: ${outputFile.path}';
        _isProcessing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Export successful'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Failed to export: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _validateAndUploadToBackend() async {
    if (_importedQuestions.isEmpty) {
      setState(() {
        _status = 'Import questions first before backend upload.';
      });
      return;
    }

    final datasetName = _datasetNameController.text.trim();
    if (datasetName.isEmpty) {
      setState(() {
        _status = 'Dataset name is required for backend import.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Validating questions with backend...';
    });

    try {
      final service = ref.read(questionIngestionServiceProvider);
      final validation = await service.validateBulkImport(
        questions: _importedQuestions,
        datasetName: datasetName,
      );

      final errors = (validation['errors'] as List?) ?? const [];
      if (errors.isNotEmpty) {
        setState(() {
          _isProcessing = false;
          _status = 'Validation failed: ${errors.length} issue(s) found.';
        });
        return;
      }

      setState(() {
        _status = 'Validation passed. Uploading to backend...';
      });

      final importResponse = await service.importBulkQuestions(
        questions: _importedQuestions,
        datasetName: datasetName,
        publishAfterImport: _publishAfterImport,
      );

      final imported = importResponse['importedCount'] ?? _importedQuestions.length;
      setState(() {
        _isProcessing = false;
        _status = 'Backend import successful: $imported question(s) synced to $datasetName.';
      });
    } on ApiRequestException catch (e) {
      setState(() {
        _isProcessing = false;
        _status = 'Backend import failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = 'Backend import failed: $e';
      });
    }
  }

  Future<void> _publishDataset(bool publish) async {
    final datasetName = _datasetNameController.text.trim();
    if (datasetName.isEmpty) {
      setState(() {
        _status = 'Dataset name is required for publish actions.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = publish ? 'Publishing dataset...' : 'Unpublishing dataset...';
    });

    try {
      final service = ref.read(questionIngestionServiceProvider);
      if (publish) {
        await service.publishDataset(datasetName);
      } else {
        await service.unpublishDataset(datasetName);
      }

      setState(() {
        _isProcessing = false;
        _status = publish
            ? 'Dataset $datasetName published successfully.'
            : 'Dataset $datasetName unpublished successfully.';
      });
    } on ApiRequestException catch (e) {
      setState(() {
        _isProcessing = false;
        _status = 'Dataset action failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = 'Dataset action failed: $e';
      });
    }
  }

  @override
  void dispose() {
    _datasetNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'File Import/Export',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.import_export, color: Colors.white, size: 40),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import & Export',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage your question database',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Actions Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE9ECEF),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.file_upload, color: Color(0xFF10B981), size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Import Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isProcessing ? null : _importFromFile,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: _isProcessing
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Import Questions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Export Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isProcessing ? null : _exportToFile,
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Export Questions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Backend Ingestion Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backend Ingestion Workflow',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _datasetNameController,
                  decoration: InputDecoration(
                    labelText: 'Dataset Name',
                    hintText: 'community_pack',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _publishAfterImport,
                  onChanged: _isProcessing
                      ? null
                      : (value) => setState(() => _publishAfterImport = value),
                  title: const Text('Publish immediately after import'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _validateAndUploadToBackend,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Validate + Import'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : () => _publishDataset(true),
                        icon: const Icon(Icons.publish),
                        label: const Text('Publish'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : () => _publishDataset(false),
                        icon: const Icon(Icons.unpublished),
                        label: const Text('Unpublish'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Status Card
          if (_status != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _status!.contains('Failed') || _status!.contains('Error')
                    ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                    : const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _status!.contains('Failed') || _status!.contains('Error')
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _status!.contains('Failed') || _status!.contains('Error')
                        ? Icons.error_outline
                        : Icons.info_outline,
                    color: _status!.contains('Failed') || _status!.contains('Error')
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _status!,
                      style: TextStyle(
                        fontSize: 14,
                        color: _status!.contains('Failed') || _status!.contains('Error')
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_status != null) const SizedBox(height: 24),

          // Questions List Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE9ECEF),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.list, color: Color(0xFF6366F1), size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Imported Questions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const Spacer(),
                      if (_importedQuestions.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_importedQuestions.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.grey[200]),

                SizedBox(
                  height: 400,
                  child: _importedQuestions.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No questions imported yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Import a file to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _importedQuestions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final question = _importedQuestions[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question.question,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Category: ${question.category}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
