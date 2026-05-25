import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dto/study_dto.dart';
import '../../game/providers/study_providers.dart';

/// Create or edit a custom study set.
///
/// Pass [editSetId] to load an existing set for editing.
/// Omit it (or pass null) to create a new set.
class StudyCustomSetScreen extends ConsumerStatefulWidget {
  final String? editSetId;

  const StudyCustomSetScreen({super.key, this.editSetId});

  @override
  ConsumerState<StudyCustomSetScreen> createState() =>
      _StudyCustomSetScreenState();
}

class _StudyCustomSetScreenState extends ConsumerState<StudyCustomSetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  // Questions available for selection (loaded from the "all sets" list)
  List<StudyQuestion> _availableQuestions = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String _searchQuery = '';

  bool get _isEdit => widget.editSetId != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(studyServiceProvider);

      // If editing, load the existing set to prefill fields
      if (_isEdit) {
        final detail = await service.fetchStudySet(widget.editSetId!);
        _titleController.text = detail.title;
        _descriptionController.text = detail.description;
        _selectedIds.addAll(detail.questions.map((q) => q.id));
        _availableQuestions = detail.questions;
      }

      // Load questions from all study sets for selection
      final sets = await service.fetchStudySets();
      final questionMap = <String, StudyQuestion>{};
      for (final set in sets.take(5)) {
        try {
          final detail = await service.fetchStudySet(set.id);
          for (final q in detail.questions) {
            questionMap[q.id] = q;
          }
        } catch (_) {
          // Best-effort — skip sets that fail to load
        }
      }
      if (mounted) {
        setState(() {
          _availableQuestions = questionMap.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one question.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = ref.read(studyServiceProvider);
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final questionIds = _selectedIds.toList();

      final StudySetDetail result;
      if (_isEdit) {
        result = await service.updateStudySet(
          setId: widget.editSetId!,
          title: title,
          description: description,
          questionIds: questionIds,
        );
      } else {
        result = await service.createStudySet(
          title: title,
          description: description,
          questionIds: questionIds,
        );
      }

      ref.invalidate(studySetsProvider);
      if (mounted) context.go('/study/set/${result.id}');
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  List<StudyQuestion> get _filteredQuestions {
    if (_searchQuery.isEmpty) return _availableQuestions;
    final q = _searchQuery.toLowerCase();
    return _availableQuestions
        .where((question) =>
            question.text.toLowerCase().contains(q) ||
            question.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15183A),
        title: Text(
          _isEdit ? 'Edit Study Set' : 'Create Study Set',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadInitialData)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildFields(),
          const Divider(color: Colors.white12, height: 1),
          _buildQuestionSearch(),
          Expanded(child: _buildQuestionList()),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Title', Icons.title),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Description (optional)', Icons.notes),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_selectedIds.length} question${_selectedIds.length == 1 ? '' : 's'} selected',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration('Search questions…', Icons.search),
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
      ),
    );
  }

  Widget _buildQuestionList() {
    final questions = _filteredQuestions;
    if (questions.isEmpty) {
      return const Center(
        child: Text(
          'No questions found.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        final selected = _selectedIds.contains(question.id);
        return CheckboxListTile(
          value: selected,
          onChanged: (_) => setState(() {
            if (selected) {
              _selectedIds.remove(question.id);
            } else {
              _selectedIds.add(question.id);
            }
          }),
          title: Text(
            question.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          subtitle: Text(
            '${question.category} · ${question.difficulty}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          checkColor: Colors.white,
          activeColor: const Color(0xFF6366F1),
          side: const BorderSide(color: Colors.white24),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1)),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
