import 'package:flutter/material.dart';

// Enum to represent the crossword categories
enum CrosswordCategory {
  scienceTech,
  vocabulary,
  historyGeo,
  literaturePhilosophy,
  cultureMisc,
}

// Helper extension to get a user-friendly name for each category
extension CrosswordCategoryExtension on CrosswordCategory {
  String get displayName {
    switch (this) {
      case CrosswordCategory.scienceTech:
        return 'Science & Tech';
      case CrosswordCategory.vocabulary:
        return 'Vocabulary';
      case CrosswordCategory.historyGeo:
        return 'History & Geo';
      case CrosswordCategory.literaturePhilosophy:
        return 'Literature';
      case CrosswordCategory.cultureMisc:
        return 'Culture';
      default:
        return '';
    }
  }
}

class CrosswordSettingsDialog extends StatefulWidget {
  final CrosswordCategory initialCategory;

  const CrosswordSettingsDialog({
    super.key,
    required this.initialCategory,
  });

  @override
  State<CrosswordSettingsDialog> createState() =>
      _CrosswordSettingsDialogState();
}

class _CrosswordSettingsDialogState extends State<CrosswordSettingsDialog> {
  late CrosswordCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('New Puzzle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<CrosswordCategory>(
            value: _selectedCategory,
            items: CrosswordCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // Return the selected category when the dialog is closed
            Navigator.of(context).pop(_selectedCategory);
          },
          child: const Text('Start Game'),
        ),
      ],
    );
  }
}
