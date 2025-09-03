import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:trivia_tycoon/admin/questions/question_editor_screen.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import '../../core/services/question/question_api_service.dart';
import '../widgets/fab_menu.dart';

class QuestionListScreen extends StatefulWidget {
  const QuestionListScreen({super.key});

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  List<QuestionModel> _questions = [];
  List<QuestionModel> _filtered = [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Set<String> _selectedIds = {};
  final List<String> _activeTags = []; // user-selected tags
  late AppCacheService appCache;

  final int _pageSize = 10;
  int _currentPage = 0;
  bool _bulkMode = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final data = await appCache.getQuestions(); // Your method to load saved questions
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
        final matchesTags = _activeTags.isEmpty || _activeTags.every((tag) => tags.contains(tags));
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
        title: Text(question.question),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: question.options.map((o) => Text(o)).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  void _deleteQuestion(String id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete this question?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _questions.removeWhere((q) => q.id == id));
      await appCache.saveQuestions(_questions);
      _applyFilters();
    }
  }

  void _deleteSelected() async {
    final confirmed = await showDialog(
       context: context,
       builder: (_) => AlertDialog(
         title: const Text("Delete selected questions?"),
         content: const Text("This will delete all selected questions."),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete All")),
         ],
       )
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
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final decoded = json.decode(content) as List<dynamic>;

      final imported = decoded.map((e) => QuestionModel.fromJson(e)).toList();
      setState(() => _questions.addAll(imported));
      await appCache.saveQuestions(_questions);
      _applyFilters();
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Import complete')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📤 Export successful')));
    }
  }

  Future<void> _syncFromServer() async {
    final fetched = await QuestionApiService.fetchQuestions();
    setState(() {
      _questions = fetched;
      _applyFilters();
    });
    await appCache.saveQuestions(fetched);
  }

  Future<void> _syncToServer() async {
    await QuestionApiService.uploadQuestions(_questions);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Synced to server')));
  }

  void _handleAddQuestion() async {
    final newQ = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionEditorScreen()));
    if (newQ != null && newQ is QuestionModel) {
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
      appBar: AppBar(
        title: const Text("📋 Question List"),
      ),
      body: Column(
        children: [
          _buildFilters(categories),
          _buildTagFilter(),
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: Text("Delete (${_selectedIds.length})"),
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
                    child: Text(_selectedIds.length == _filtered.length ? "Deselect All" : "Select All"),
                  )
                ],
              ),
            ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text("No questions found."))
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

                  // Reflect order in main list
                  _questions = _filtered.toList();
                  appCache.saveQuestions(_questions);
                });
              },
              itemBuilder: (context, index) {
                final q = _paginated()[index];
                return ListTile(
                  key: ValueKey(q.id),
                  title: Text(q.question),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Category: ${q.category} • Difficulty: ${q.difficulty}"),
                      if (q.tags != null && q.tags!.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: q.tags!.map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 12)))).toList(),
                        ),
                    ],
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.preview), onPressed: () => _previewQuestion(q)),
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editQuestion(q, index)),
                      if (_bulkMode)
                      Checkbox(
                        value: _selectedIds.contains(q.id),
                        onChanged: (value) {
                          setState(() {
                            value == true ? _selectedIds.add(q.id) : _selectedIds.remove(q.id);
                          });
                        },
                      ),
                      Icon(Icons.drag_handle),
                    ],
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

  Widget _buildFilters(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search questions...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedCategory,
            onChanged: (value) {
              _selectedCategory = value!;
              _applyFilters();
            },
            items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilter() {
    final allTags = _questions.expand((q) => q.tags ?? []).toSet().toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: Wrap(
        spacing: 8,
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
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagination(int pageCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null),
          Text('Page ${_currentPage + 1} of $pageCount'),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage < pageCount - 1 ? () => setState(() => _currentPage++) : null),
        ],
      ),
    );
  }
}
