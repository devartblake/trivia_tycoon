import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../game/models/answer.dart';
import '../widgets/question_editor_form.dart';
import '../../game/models/question_model.dart';

class QuestionEditorScreen extends StatefulWidget {
  final QuestionModel? initialQuestion; // Pass null for new question
  final void Function(QuestionModel)? onSubmit; // Optional callback

  const QuestionEditorScreen({
    super.key,
    this.initialQuestion,
    this.onSubmit,
  });

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late QuestionModel _editedQuestion;

  @override
  void initState() {
    super.initState();
    _editedQuestion = widget.initialQuestion ??
      QuestionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: '',
        options: ['', '', '', ''],
        answers: List.generate(4, (i) => Answer(text: '', isCorrect: i == 0)),
        correctAnswer: '',
        correctIndex: 0,
        difficulty: 1, // Must be an int
        category: '',
        type: 'multiple_choice',
      );
    }

  void _saveQuestion() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final box = await Hive.openBox<QuestionModel>('questions');
      await box.put(_editedQuestion.id, _editedQuestion); // Save or update

      widget.onSubmit?.call(_editedQuestion);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Question saved to Hive!')),
      );
      Navigator.pop(context, _editedQuestion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialQuestion == null ? 'Add Question' : 'Edit Question'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQuestion,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: QuestionEditorForm(
          initialQuestion: _editedQuestion,
          onSubmit: (updated) => _editedQuestion = updated,
        ),
      ),
    );
  }
}
