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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Input
          _buildSectionHeader('Question Details', Icons.quiz, const Color(0xFF6366F1)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _questionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Question',
              hintText: 'Enter your question here...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
            ),
            validator: (value) => (value == null || value.isEmpty) ? 'Enter a question' : null,
          ),

          const SizedBox(height: 24),

          // Answer Options
          _buildSectionHeader('Answer Options', Icons.checklist, const Color(0xFF10B981)),
          const SizedBox(height: 12),
          ...List.generate(_optionControllers.length, (index) {
            final isCorrect = _correctAnswerIndex == index;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isCorrect ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCorrect ? const Color(0xFF10B981) : Colors.grey[200]!,
                  width: isCorrect ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Radio<int>(
                  value: index,
                  groupValue: _correctAnswerIndex,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (value) => setState(() => _correctAnswerIndex = value!),
                ),
                title: TextFormField(
                  controller: _optionControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Option ${String.fromCharCode(65 + index)}',
                    border: InputBorder.none,
                    labelStyle: TextStyle(
                      color: isCorrect ? const Color(0xFF10B981) : Colors.grey[600],
                      fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Enter option ${index + 1}' : null,
                ),
                trailing: isCorrect
                    ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                    : null,
              ),
            );
          }),

          const SizedBox(height: 24),

          // Category & Difficulty
          _buildSectionHeader('Classification', Icons.category, const Color(0xFF3B82F6)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStyledDropdown(
                  value: _selectedCategory,
                  items: _categories,
                  label: 'Category',
                  icon: Icons.folder,
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStyledDropdown(
                  value: _selectedDifficulty,
                  items: _difficulties,
                  label: 'Difficulty',
                  icon: Icons.signal_cellular_alt,
                  onChanged: (value) => setState(() => _selectedDifficulty = value!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Media Section
          _buildSectionHeader('Media & Resources', Icons.image, const Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.image, size: 20),
                        label: const Text("Pick Image"),
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _videoUrlController,
                  decoration: InputDecoration(
                    labelText: 'Video URL (Optional)',
                    prefixIcon: const Icon(Icons.video_library, color: Color(0xFFF59E0B)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Power-ups Section
          _buildSectionHeader('Power-ups', Icons.flash_on, const Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _powerUpHintController,
                  decoration: InputDecoration(
                    labelText: 'Power-up Hint',
                    prefixIcon: const Icon(Icons.lightbulb, color: Color(0xFFEF4444)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStyledDropdown(
                  value: _selectedPowerUpType,
                  items: _powerUpTypes,
                  label: 'Power-up Type',
                  icon: Icons.settings_power,
                  onChanged: (value) => setState(() => _selectedPowerUpType = value),
                  allowNull: true,
                ),
                const SizedBox(height: 16),
                _buildToggleOption('Show Hint Initially', _showHint, Icons.visibility, (val) => setState(() => _showHint = val)),
                _buildToggleOption('Boosted Time', _isBoostedTime, Icons.timer, (val) => setState(() => _isBoostedTime = val)),
                _buildToggleOption('Shield Active', _isShielded, Icons.shield, (val) => setState(() => _isShielded = val)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
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
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _submitForm,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          widget.initialQuestion != null ? 'Update Question' : 'Save Question',
                          style: const TextStyle(
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
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
    bool allowNull = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: InputBorder.none,
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToggleOption(String title, bool value, IconData icon, void Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? const Color(0xFFEF4444) : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? const Color(0xFFEF4444) : Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                color: value ? const Color(0xFF1A1A1A) : Colors.grey[700],
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}
