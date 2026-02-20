import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../game/providers/question_providers.dart';
import '../../../../game/services/quiz_category.dart';

class FeaturedCategoryChip extends ConsumerWidget {
  final QuizCategory category;

  const FeaturedCategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryStatsAsync = ref.watch(categoryStatsProvider(category));

    return GestureDetector(
      onTap: () {
        context.push('/quiz/category/${category.name}');
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: category.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: category.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: category.primaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            categoryStatsAsync.when(
              data: (stats) => Text(
                '${stats['questionCount']}q',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
              loading: () => const SizedBox(height: 10),
              error: (error, stack) => const SizedBox(height: 10),
            ),
          ],
        ),
      ),
    );
  }
}