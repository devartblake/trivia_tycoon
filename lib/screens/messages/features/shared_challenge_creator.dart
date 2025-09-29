import 'package:flutter/material.dart';
import 'dialogs/in_chat_gifting_dialog.dart';

class SharedChallengeCreator extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String currentUserId;
  final Function(Map<String, dynamic> challenge)? onChallengeCreated;

  const SharedChallengeCreator({
    super.key,
    required this.recipientId,
    required this.recipientName,
    required this.currentUserId,
    this.onChallengeCreated,
  });

  @override
  State<SharedChallengeCreator> createState() => _SharedChallengeCreatorState();
}

class _SharedChallengeCreatorState extends State<SharedChallengeCreator> {
  String _selectedCategory = 'Science';
  int _selectedQuestions = 10;
  String _selectedDifficulty = 'Medium';
  int _selectedWager = 0;

  final List<String> _categories = ['Science', 'History', 'Sports', 'Movies', 'Music', 'General'];
  final List<int> _questionOptions = [5, 10, 15, 20];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard', 'Expert'];
  final List<int> _wagerOptions = [0, 10, 25, 50, 100];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sports_esports,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge ${widget.recipientName}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Create a quiz challenge',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Category',
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Number of Questions',
                  Wrap(
                    spacing: 8,
                    children: _questionOptions.map((count) {
                      final isSelected = _selectedQuestions == count;
                      return ChoiceChip(
                        label: Text('$count'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedQuestions = count);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Difficulty',
                  Wrap(
                    spacing: 8,
                    children: _difficulties.map((difficulty) {
                      final isSelected = _selectedDifficulty == difficulty;
                      return ChoiceChip(
                        label: Text(difficulty),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedDifficulty = difficulty);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Wager (Optional)',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: _wagerOptions.map((wager) {
                          final isSelected = _selectedWager == wager;
                          return ChoiceChip(
                            label: wager == 0
                                ? const Text('No Wager')
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('$wager'),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedWager = wager);
                            },
                          );
                        }).toList(),
                      ),
                      if (_selectedWager > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Winner takes all coins!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _createChallenge,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Challenge'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _createChallenge() {
    final challenge = {
      'challengerId': widget.currentUserId,
      'recipientId': widget.recipientId,
      'recipientName': widget.recipientName,
      'category': _selectedCategory,
      'questions': _selectedQuestions,
      'difficulty': _selectedDifficulty,
      'wager': _selectedWager,
      'createdAt': DateTime.now().toIso8601String(),
    };

    widget.onChallengeCreated?.call(challenge);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Challenge sent to ${widget.recipientName}!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to challenge details
          },
        ),
      ),
    );
  }
}

// Helper function to show in-chat gifting
Future<void> showInChatGifting(
    BuildContext context, {
      required String recipientId,
      required String recipientName,
      Function(String giftId, int coins)? onGiftSent,
    }) {
  return showDialog(
    context: context,
    builder: (context) => InChatGiftingDialog(
      recipientId: recipientId,
      recipientName: recipientName,
      onGiftSent: onGiftSent,
    ),
  );
}

// Helper function to show challenge creator
Future<void> showChallengeCreator(
    BuildContext context, {
      required String recipientId,
      required String recipientName,
      required String currentUserId,
      Function(Map<String, dynamic> challenge)? onChallengeCreated,
    }) {
  return showDialog(
    context: context,
    builder: (context) => SharedChallengeCreator(
      recipientId: recipientId,
      recipientName: recipientName,
      currentUserId: currentUserId,
      onChallengeCreated: onChallengeCreated,
    ),
  );
}
