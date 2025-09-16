import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Science',
      'History',
      'Sports',
      'Geography',
      'Technology',
      'Literature',
      'Mathematics',
      'Entertainment',
      'Music',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () => context.push('/category-quiz/${category.toLowerCase()}'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getCategoryColor(category).withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getCategoryIcon(category), size: 32, color: _getCategoryColor(category)),
                            const SizedBox(height: 8),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getCategoryColor(category),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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
      case 'mathematics':
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
      case 'mathematics':
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