import 'package:flutter/material.dart';
import '../../../core/models/answered_question_record.dart';

class QuizReviewScreen extends StatelessWidget {
  final List<AnsweredQuestionRecord> records;

  const QuizReviewScreen({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final correct = records.where((r) => r.isCorrect).length;
    final wrong = records.length - correct;
    final accuracy = records.isEmpty
        ? 0
        : (correct / records.length * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Review Answers'),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.grey.shade900],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatColumn(
                      label: 'Correct',
                      value: '$correct',
                      color: Colors.green,
                    ),
                    _StatColumn(
                      label: 'Wrong',
                      value: '$wrong',
                      color: Colors.red,
                    ),
                    _StatColumn(
                      label: 'Accuracy',
                      value: '$accuracy%',
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Question list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return _QuestionTile(record: record, index: index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final AnsweredQuestionRecord record;
  final int index;

  const _QuestionTile({
    required this.record,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.grey.shade900,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              record.isCorrect ? Icons.check_circle : Icons.cancel,
              color: record.isCorrect ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question $index',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    record.isCorrect ? 'Correct' : 'Wrong',
                    style: TextStyle(
                      fontSize: 12,
                      color: record.isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Pattern',
                  value: record.prompt,
                  valueColor: Colors.cyan,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Your Answer',
                  value: record.yourAnswer,
                  valueColor: record.isCorrect ? Colors.green : Colors.orange,
                ),
                if (!record.isCorrect) ...[
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Correct Answer',
                    value: record.correctAnswer,
                    valueColor: Colors.green,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
