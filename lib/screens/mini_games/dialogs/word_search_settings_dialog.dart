import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Enum to represent the difficulty levels
enum WordSearchDifficulty { easy, medium, hard }

class WordSearchSettingsDialog extends StatefulWidget {
  final WordSearchDifficulty initialDifficulty;

  const WordSearchSettingsDialog({
    super.key,
    required this.initialDifficulty,
  });

  @override
  State<WordSearchSettingsDialog> createState() =>
      _WordSearchSettingsDialogState();
}

class _WordSearchSettingsDialogState extends State<WordSearchSettingsDialog> {
  late WordSearchDifficulty _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.initialDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Change Difficulty'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<WordSearchDifficulty>(
              groupValue: _selectedDifficulty,
              onValueChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDifficulty = value;
                  });
                }
              },
              children: const {
                WordSearchDifficulty.easy: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Easy'),
                ),
                WordSearchDifficulty.medium: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Medium'),
                ),
                WordSearchDifficulty.hard: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Hard'),
                ),
              },
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
            // Return the selected difficulty when the dialog is closed
            Navigator.of(context).pop(_selectedDifficulty);
          },
          child: const Text('New Game'),
        ),
      ],
    );
  }
}
