import 'package:flutter/material.dart';

class ChatTheme {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color bubbleColor;
  final int price;
  final bool isPremium;
  final bool isOwned;

  const ChatTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.bubbleColor,
    required this.price,
    this.isPremium = false,
    this.isOwned = false,
  });
}

class ChatThemesScreen extends StatefulWidget {
  final String currentUserId;

  const ChatThemesScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<ChatThemesScreen> createState() => _ChatThemesScreenState();
}

class _ChatThemesScreenState extends State<ChatThemesScreen> {
  String? _selectedThemeId;

  final List<ChatTheme> _themes = [
    const ChatTheme(
      id: 'default',
      name: 'Default',
      description: 'The classic look',
      primaryColor: Colors.blue,
      secondaryColor: Colors.lightBlue,
      backgroundColor: Colors.white,
      bubbleColor: Color(0xFFE3F2FD),
      price: 0,
      isOwned: true,
    ),
    const ChatTheme(
      id: 'dark',
      name: 'Dark Mode',
      description: 'Easy on the eyes',
      primaryColor: Colors.deepPurple,
      secondaryColor: Colors.purple,
      backgroundColor: Color(0xFF121212),
      bubbleColor: Color(0xFF2C2C2C),
      price: 100,
    ),
    const ChatTheme(
      id: 'ocean',
      name: 'Ocean Breeze',
      description: 'Calming blue waves',
      primaryColor: Colors.cyan,
      secondaryColor: Colors.teal,
      backgroundColor: Color(0xFFE0F7FA),
      bubbleColor: Color(0xFFB2EBF2),
      price: 250,
    ),
    const ChatTheme(
      id: 'sunset',
      name: 'Sunset Glow',
      description: 'Warm and vibrant',
      primaryColor: Colors.orange,
      secondaryColor: Colors.deepOrange,
      backgroundColor: Color(0xFFFFF3E0),
      bubbleColor: Color(0xFFFFE0B2),
      price: 250,
    ),
    const ChatTheme(
      id: 'forest',
      name: 'Forest Green',
      description: 'Natural and fresh',
      primaryColor: Colors.green,
      secondaryColor: Colors.lightGreen,
      backgroundColor: Color(0xFFE8F5E9),
      bubbleColor: Color(0xFFC8E6C9),
      price: 250,
    ),
    const ChatTheme(
      id: 'galaxy',
      name: 'Galaxy',
      description: 'Cosmic adventure',
      primaryColor: Colors.deepPurple,
      secondaryColor: Colors.purple,
      backgroundColor: Color(0xFF1A1A2E),
      bubbleColor: Color(0xFF16213E),
      price: 500,
      isPremium: true,
    ),
    const ChatTheme(
      id: 'neon',
      name: 'Neon Lights',
      description: 'Futuristic vibes',
      primaryColor: Color(0xFFFF00FF),
      secondaryColor: Color(0xFF00FFFF),
      backgroundColor: Color(0xFF0A0E27),
      bubbleColor: Color(0xFF1E1E3F),
      price: 500,
      isPremium: true,
    ),
    const ChatTheme(
      id: 'cherry',
      name: 'Cherry Blossom',
      description: 'Delicate and beautiful',
      primaryColor: Color(0xFFFF69B4),
      secondaryColor: Color(0xFFFFB6C1),
      backgroundColor: Color(0xFFFFF0F5),
      bubbleColor: Color(0xFFFFE4E1),
      price: 350,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Themes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showThemeInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceCard(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _themes.length,
              itemBuilder: (context, index) {
                return _buildThemeCard(_themes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.amber,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Balance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '1,250 Coins',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
            child: const Text('Get More'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(ChatTheme theme) {
    return GestureDetector(
      onTap: () => _showThemePreview(theme),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.secondaryColor],
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.bubbleColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Hello!',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Hi there!',
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (theme.isPremium)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star, size: 12),
                              SizedBox(width: 2),
                              Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (theme.isOwned)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (!theme.isOwned) ...[
                          const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${theme.price}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Owned',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePreview(ChatTheme theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.secondaryColor],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theme.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            theme.description,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    if (!theme.isOwned)
                      FilledButton.icon(
                        onPressed: () => _purchaseTheme(theme),
                        icon: const Icon(Icons.shopping_cart, size: 18),
                        label: Text('${theme.price}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.primaryColor,
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyTheme(theme);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.primaryColor,
                        ),
                        child: const Text('Apply'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPreviewMessage(
                      'Hey! How are you?',
                      false,
                      theme,
                    ),
                    _buildPreviewMessage(
                      'I\'m doing great! Just won another trivia game 🎉',
                      true,
                      theme,
                    ),
                    _buildPreviewMessage(
                      'Nice! Want to challenge me?',
                      false,
                      theme,
                    ),
                    _buildPreviewMessage(
                      'Sure! Let\'s do Science category',
                      true,
                      theme,
                    ),
                    _buildPreviewMessage(
                      'You\'re on! 💪',
                      false,
                      theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewMessage(String text, bool isMe, ChatTheme theme) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? theme.primaryColor : theme.bubbleColor,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _purchaseTheme(ChatTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${theme.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Do you want to purchase this theme?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${theme.price} Coins',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              _confirmPurchase(theme);
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  void _confirmPurchase(ChatTheme theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${theme.name} theme purchased!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Apply',
          textColor: Colors.white,
          onPressed: () => _applyTheme(theme),
        ),
      ),
    );
  }

  void _applyTheme(ChatTheme theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${theme.name} theme applied!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showThemeInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Themes'),
        content: const Text(
          'Personalize your chat experience with beautiful themes! '
              'Themes change the colors and appearance of your chat messages. '
              'Purchase themes with coins earned from playing games.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
