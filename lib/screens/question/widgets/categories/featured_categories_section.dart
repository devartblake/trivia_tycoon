import 'package:flutter/material.dart';
import '../../../../game/services/quiz_category.dart';
import 'featured_category_chip.dart';

class FeaturedCategoriesSection extends StatelessWidget {
  final List<QuizCategory> categories;

  const FeaturedCategoriesSection({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox();

    // Show a horizontal list of featured categories
    final featuredCategories = categories.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore More',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredCategories.length,
            itemBuilder: (context, index) {
              final category = featuredCategories[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < featuredCategories.length - 1 ? 12 : 0,
                ),
                child: FeaturedCategoryChip(category: category),
              );
            },
          ),
        ),
      ],
    );
  }
}