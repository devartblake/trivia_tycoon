import 'package:flutter/material.dart';

class InChatGiftingDialog extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final Function(String giftId, int coins)? onGiftSent;

  const InChatGiftingDialog({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.onGiftSent,
  });

  @override
  State<InChatGiftingDialog> createState() => _InChatGiftingDialogState();
}

class _InChatGiftingDialogState extends State<InChatGiftingDialog> {
  String? _selectedGiftId;

  final List<Map<String, dynamic>> _gifts = [
    {'id': 'heart', 'icon': '❤️', 'name': 'Heart', 'coins': 10},
    {'id': 'star', 'icon': '⭐', 'name': 'Star', 'coins': 25},
    {'id': 'trophy', 'icon': '🏆', 'name': 'Trophy', 'coins': 50},
    {'id': 'crown', 'icon': '👑', 'name': 'Crown', 'coins': 100},
    {'id': 'diamond', 'icon': '💎', 'name': 'Diamond', 'coins': 250},
    {'id': 'rocket', 'icon': '🚀', 'name': 'Rocket', 'coins': 500},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Gift',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'to ${widget.recipientName}',
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _gifts.length,
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                final isSelected = _selectedGiftId == gift['id'];

                return GestureDetector(
                  onTap: () => setState(() => _selectedGiftId = gift['id']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          gift['icon'],
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gift['name'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.monetization_on,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${gift['coins']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedGiftId != null ? _sendGift : null,
                icon: const Icon(Icons.send),
                label: const Text('Send Gift'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendGift() {
    if (_selectedGiftId == null) return;

    final gift = _gifts.firstWhere((g) => g['id'] == _selectedGiftId);
    widget.onGiftSent?.call(_selectedGiftId!, gift['coins']);

    Navigator.pop(context);

    // Show success animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(gift['icon'], style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Sent ${gift['name']} to ${widget.recipientName}!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
