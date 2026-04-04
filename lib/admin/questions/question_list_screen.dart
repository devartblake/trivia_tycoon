import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:trivia_tycoon/admin/questions/question_editor_screen.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import '../../game/providers/riverpod_providers.dart';
import '../widgets/fab_menu.dart';

class QuestionListScreen extends ConsumerStatefulWidget {
  const QuestionListScreen({super.key});

  @override
  ConsumerState<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends ConsumerState<QuestionListScreen> {
  List<QuestionModel> _questions = [];
  List<QuestionModel> _filtered = [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Set<String> _selectedIds = {};
  final List<String> _activeTags = [];
  late AppCacheService appCache;

  final int _pageSize = 10;
  int _currentPage = 0;
  bool _bulkMode = false;
  String? _serverSyncStatus;

  @override
  void initState() {
    super.initState();
    appCache = ref.read(serviceManagerProvider).appCacheService;
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final data = await appCache.getQuestions();
    setState(() {
      _questions = data;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filtered = _questions.where((q) {
        final matchesQuery = q.question.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' || q.category == _selectedCategory;
        final tags = q.tags ?? [];
        final matchesTags = _activeTags.isEmpty || _activeTags.every((tag) => tags.contains(tag));
        return matchesQuery && matchesCategory && matchesTags;
      }).toList();
    });
  }

  void _editQuestion(QuestionModel question, int index) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuestionEditorScreen(initialQuestion: question)),
    );

    if (updated != null && updated is QuestionModel) {
      final i = _questions.indexWhere((q) => q.id == question.id);
      if (i != -1) {
        try {
          final serviceManager = ref.read(serviceManagerProvider);
          await serviceManager.apiService.patch('/admin/questions/${updated.id}',
              body: updated.toJson());
        } catch (_) {
          // Keep local update behavior when backend patch is unavailable.
        }
        setState(() => _questions[i] = updated);
        await appCache.saveQuestions(_questions);
        _applyFilters();
      }
    }
  }

  void _previewQuestion(QuestionModel question) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          question.question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...question.options.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: entry.key == question.correctIndex
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + entry.key),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: entry.key == question.correctIndex
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _deleteQuestion(String id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Question?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final serviceManager = ref.read(serviceManagerProvider);
        await serviceManager.apiService.delete('/admin/questions/$id');
      } catch (_) {
        // Keep local delete behavior even if backend is unavailable.
      }
      setState(() => _questions.removeWhere((q) => q.id == id));
      await appCache.saveQuestions(_questions);
      _applyFilters();
    }
  }

  void _deleteSelected() async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Selected Questions?"),
        content: Text("This will delete ${_selectedIds.length} questions."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text("Delete All"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _questions.removeWhere((q) => _selectedIds.contains(q.id)));
      _selectedIds.clear();
      _bulkMode = false;
      await appCache.saveQuestions(_questions);
      _applyFilters();
    }
  }

  List<QuestionModel> _paginated() {
    final start = _currentPage * _pageSize;
    final end = (_currentPage + 1) * _pageSize;
    return _filtered.sublist(start, end > _filtered.length ? _filtered.length : end);
  }

  Future<void> _importQuestions() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final decoded = json.decode(content) as List<dynamic>;

      final imported = decoded.map((e) => QuestionModel.fromJson(e)).toList();
      setState(() => _questions.addAll(imported));
      await appCache.saveQuestions(_questions);
      _applyFilters();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Import complete'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _exportQuestions() async {
    final jsonString = json.encode(_questions.map((q) => q.toJson()).toList());
    final filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Questions as JSON',
      fileName: 'questions.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (filePath != null) {
      final file = File(filePath);
      await file.writeAsString(jsonString);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _syncFromServer() async {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response =
          await serviceManager.apiService.get('/admin/questions?page=1&pageSize=500');
      final envelope = serviceManager.apiService
          .parsePageEnvelope<Map<String, dynamic>>(response, (json) => json);
      final fetched = envelope.items.map(QuestionModel.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _questions = fetched;
        _serverSyncStatus =
            'Server sync OK • page ${envelope.page}/${envelope.totalPages} • total ${envelope.total}';
        _applyFilters();
      });
      await appCache.saveQuestions(fetched);
    } on ApiRequestException catch (e) {
      if (!mounted) return;
      final errorCode = e.errorCode != null ? ' [${e.errorCode}]' : '';
      setState(() {
        _serverSyncStatus = 'Server sync failed$errorCode: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _serverSyncStatus = 'Server sync failed: $e';
      });
    }
  }

  Future<void> _syncToServer() async {
    final serviceManager = ref.read(serviceManagerProvider);
    await serviceManager.apiService.post('/admin/questions/bulk', body: {
      'mode': 'upsert',
      'questions': _questions.map((q) => q.toJson()).toList(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Synced to server'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleAddQuestion() async {
    final newQ = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestionEditorScreen()),
    );
    if (newQ != null && newQ is QuestionModel) {
      try {
        final serviceManager = ref.read(serviceManagerProvider);
        await serviceManager.apiService.post('/admin/questions', body: newQ.toJson());
      } catch (_) {
        // Keep local create behavior when backend create is unavailable.
      }
      setState(() => _questions.add(newQ));
      await appCache.saveQuestions(_questions);
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ..._questions.map((q) => q.category).toSet()];
    final pageCount = (_filtered.length / _pageSize).ceil();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Question Bank',
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
      body: Column(
        children: [
          if (_serverSyncStatus != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                _serverSyncStatus!,
                style: const TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Stats Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', _questions.length.toString(), Icons.quiz),
                  _buildStatItem('Filtered', _filtered.length.toString(), Icons.filter_list),
                  if (_selectedIds.isNotEmpty)
                    _buildStatItem('Selected', _selectedIds.length.toString(), Icons.check_circle),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filters
          _buildFilters(categories),
          _buildTagFilter(),

          // Bulk Actions
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete, size: 20),
                      label: Text("Delete (${_selectedIds.length})"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _deleteSelected,
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedIds.length == _filtered.length) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds.addAll(_filtered.map((q) => q.id));
                          }
                        });
                      },
                      child: Text(
                        _selectedIds.length == _filtered.length ? "Deselect All" : "Select All",
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Question List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No questions found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
                : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _paginated().length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  final actualOldIndex = _currentPage * _pageSize + oldIndex;
                  var actualNewIndex = _currentPage * _pageSize + newIndex;
                  if (actualNewIndex > actualOldIndex) actualNewIndex--;

                  final item = _filtered.removeAt(actualOldIndex);
                  _filtered.insert(actualNewIndex, item);

                  _questions = _filtered.toList();
                  appCache.saveQuestions(_questions);
                });
              },
              itemBuilder: (context, index) {
                final q = _paginated()[index];
                return Container(
                  key: ValueKey(q.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedIds.contains(q.id)
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFE9ECEF),
                      width: _selectedIds.contains(q.id) ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      q.question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                q.category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Level ${q.difficulty}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (q.tags != null && q.tags!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: q.tags!.map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.preview, color: Color(0xFF6366F1)),
                          onPressed: () => _previewQuestion(q),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF10B981)),
                          onPressed: () => _editQuestion(q, index),
                        ),
                        if (_bulkMode)
                          Checkbox(
                            value: _selectedIds.contains(q.id),
                            onChanged: (value) {
                              setState(() {
                                value == true
                                    ? _selectedIds.add(q.id)
                                    : _selectedIds.remove(q.id);
                              });
                            },
                          ),
                        const Icon(Icons.drag_handle, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          _buildPagination(pageCount),
        ],
      ),
      floatingActionButton: FABMenu(
        onAdd: _handleAddQuestion,
        onImport: _importQuestions,
        onExport: _exportQuestions,
        onSyncFromServer: _syncFromServer,
        onSyncToServer: _syncToServer,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9ECEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search questions...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilters();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButton<String>(
                value: _selectedCategory,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    _applyFilters();
                  });
                },
                items: categories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagFilter() {
    final allTags = _questions.expand((q) => q.tags ?? []).toSet().toList();
    if (allTags.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allTags.map((tag) {
          final selected = _activeTags.contains(tag);
          return FilterChip(
            label: Text(tag),
            selected: selected,
            onSelected: (bool value) {
              setState(() {
                value ? _activeTags.add(tag) : _activeTags.remove(tag);
                _applyFilters();
              });
            },
            selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
            checkmarkColor: const Color(0xFF6366F1),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: selected ? const Color(0xFF6366F1) : Colors.grey[300]!,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagination(int pageCount) {
    if (pageCount <= 1) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 16),
          Text(
            'Page ${_currentPage + 1} of $pageCount',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < pageCount - 1
                ? () => setState(() => _currentPage++)
                : null,
            color: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}
