import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../game/models/answer.dart';
import '../../game/models/question_model.dart';

class QuestionEditorForm extends StatefulWidget {
  final QuestionModel? initialQuestion;
  final void Function(QuestionModel question) onSubmit;

  const QuestionEditorForm({
    super.key,
    this.initialQuestion,
    required this.onSubmit,
  });

  @override
  State<QuestionEditorForm> createState() => _QuestionEditorFormState();
}

class _QuestionEditorFormState extends State<QuestionEditorForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _questionController;
  late TextEditingController _videoUrlController;
  late TextEditingController _powerUpHintController;
  late List<TextEditingController> _optionControllers;
  int _correctAnswerIndex = 0;
  String _selectedCategory = 'General';
  String _selectedDifficulty = 'Easy';
  String? _selectedPowerUpType;

  bool _showHint = false;
  bool _isBoostedTime = false;
  bool _isShielded = false;
  File? _selectedImage;

  String _difficultyLabel(dynamic difficulty) {
    if (difficulty is int) {
      switch (difficulty) {
        case 1:
          return 'Easy';
        case 2:
          return 'Medium';
        case 3:
          return 'Hard';
        default:
          return 'Easy';
      }
    } else if (difficulty is String) {
      return difficulty;
    }
    return 'Easy';
  }

  final List<String> _categories = ['General', 'Science', 'History', 'Math', 'Literature'];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> _powerUpTypes = ['Hint', 'Eliminate', 'Shield', 'Boost'];

  @override
  void initState() {
    super.initState();

    final q = widget.initialQuestion;
    _questionController = TextEditingController(text: q?.question ?? '');
    _videoUrlController = TextEditingController(text: q?.videoUrl ?? '');
    _powerUpHintController = TextEditingController(text: q?.powerUpHint ?? '');

    _optionControllers = List.generate(4, (i) {
      final options = q?.options ?? List.filled(4, '');
      return TextEditingController(text: options[i]);
    });

    _correctAnswerIndex = q?.correctIndex ?? 0;
    _selectedCategory = _categories.contains(q?.category) ? q!.category : _categories.first;

    /// Handle int difficulty stored in model
    _selectedDifficulty = _difficulties.contains(
        q?.difficulty is String ? q!.difficulty : _difficultyLabel(q?.difficulty)
    ) ? _difficultyLabel(q?.difficulty) : _difficulties.first;
    _selectedPowerUpType = q?.powerUpType;
    _showHint = q?.showHint ?? false;
    _isBoostedTime = q?.isBoostedTime ?? false;
    _isShielded = q?.isShielded ?? false;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _videoUrlController.dispose();
    _powerUpHintController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final options = _optionControllers.map((c) => c.text).toList();

      final answers = List.generate(options.length, (i) {
        return Answer(text: options[i], isCorrect: i == _correctAnswerIndex);
      });

      final correctAnswer = options[_correctAnswerIndex];
      final difficultyMap = {'Easy': 1, 'Medium': 2, 'Hard': 3};

      final newQuestion = QuestionModel(
        id: widget.initialQuestion?.id ?? const Uuid().v4(),
        category: _selectedCategory,
        question: _questionController.text,
        answers: answers,
        correctAnswer: correctAnswer,
        type: 'multiple_choice',
        difficulty: difficultyMap[_selectedDifficulty]!,
        correctIndex: _correctAnswerIndex,
        options: options,
        imageUrl: _selectedImage?.path,
        videoUrl: _videoUrlController.text,
        powerUpHint: _powerUpHintController.text,
        powerUpType: _selectedPowerUpType,
        showHint: _showHint,
        reducedOptions: null,
        multiplier: null,
        isBoostedTime: _isBoostedTime,
        isShielded: _isShielded,
      );

      widget.onSubmit(newQuestion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Question'),
              validator: (value) => (value == null || value.isEmpty) ? 'Enter a question' : null,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _optionControllers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: TextFormField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                    validator: (value) =>
                    (value == null || value.isEmpty) ? 'Enter option ${index + 1}' : null,
                  ),
                  leading: Radio<int>(
                    value: index,
                    groupValue: _correctAnswerIndex,
                    onChanged: (value) {
                      setState(() {
                        _correctAnswerIndex = value!;
                      });
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              items: _difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (value) => setState(() => _selectedDifficulty = value!),
              decoration: const InputDecoration(labelText: 'Difficulty'),
            ),
            const SizedBox(height: 24),

            // Image Picker
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Image"),
                  onPressed: _pickImage,
                ),
                if (_selectedImage != null) ...[
                  const SizedBox(width: 8),
                  Image.file(_selectedImage!, height: 40),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Video URL
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(labelText: 'Video URL'),
            ),
            const SizedBox(height: 16),

            // Power-up hint
            TextFormField(
              controller: _powerUpHintController,
              decoration: const InputDecoration(labelText: 'Power-up Hint'),
            ),

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPowerUpType,
              decoration: const InputDecoration(labelText: 'Power-up Type'),
              items: _powerUpTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedPowerUpType = value),
            ),

            const SizedBox(height: 16),

            // Toggles
            SwitchListTile(
              value: _showHint,
              onChanged: (value) => setState(() => _showHint = value),
              title: const Text("Show Hint Initially"),
            ),
            SwitchListTile(
              value: _isBoostedTime,
              onChanged: (value) => setState(() => _isBoostedTime = value),
              title: const Text("Boosted Time Power-up"),
            ),
            SwitchListTile(
              value: _isShielded,
              onChanged: (value) => setState(() => _isShielded = value),
              title: const Text("Shield Active"),
            ),

            const SizedBox(height: 24),

            Center(
              child: ElevatedButton(
                onPressed: _submitForm,
                child: Text(widget.initialQuestion != null ? 'Update Question' : 'Save Question'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
