import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryQuizScreen extends StatelessWidget {
  final String category;

  const CategoryQuizScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${category.toUpperCase()} Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getCategoryIcon(category), size: 64, color: _getCategoryColor(category)),
            const SizedBox(height: 16),
            Text(
              '${category.toUpperCase()} Quiz',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Category-specific questions coming in Phase 2',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'sports':
        return Icons.sports_soccer;
      case 'geography':
        return Icons.public;
      case 'technology':
        return Icons.computer;
      case 'literature':
        return Icons.menu_book;
      case 'math':
        return Icons.calculate;
      case 'entertainment':
        return Icons.movie;
      case 'music':
        return Icons.music_note;
      default:
        return Icons.quiz;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'science':
        return Colors.blue;
      case 'history':
        return Colors.brown;
      case 'sports':
        return Colors.green;
      case 'geography':
        return Colors.teal;
      case 'technology':
        return Colors.purple;
      case 'literature':
        return Colors.orange;
      case 'math':
        return Colors.indigo;
      case 'entertainment':
        return Colors.pink;
      case 'music':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}