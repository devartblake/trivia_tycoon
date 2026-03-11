import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';

class AvatarStep extends StatefulWidget {
  final ModernOnboardingController controller;

  const AvatarStep({
    super.key,
    required this.controller,
  });

  @override
  State<AvatarStep> createState() => _AvatarStepState();
}

class _AvatarStepState extends State<AvatarStep>
    with SingleTickerProviderStateMixin {
  String? _selectedAvatar;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  final List<AvatarOption> avatars = [
    AvatarOption(id: 'person', icon: Icons.person, color: Colors.blue, label: 'Classic'),
    AvatarOption(id: 'face', icon: Icons.face, color: Colors.green, label: 'Friendly'),
    AvatarOption(id: 'account_circle', icon: Icons.account_circle, color: Colors.orange, label: 'Circle'),
    AvatarOption(id: 'sentiment_satisfied', icon: Icons.sentiment_satisfied, color: Colors.purple, label: 'Happy'),
    AvatarOption(id: 'child_care', icon: Icons.child_care, color: Colors.red, label: 'Young'),
    AvatarOption(id: 'psychology', icon: Icons.psychology, color: Colors.teal, label: 'Brainy'),
    AvatarOption(id: 'sports_esports', icon: Icons.sports_esports, color: Colors.indigo, label: 'Gamer'),
    AvatarOption(id: 'school', icon: Icons.school, color: Colors.brown, label: 'Scholar'),
    AvatarOption(id: 'emoji_events', icon: Icons.emoji_events, color: Colors.amber, label: 'Champion'),
    AvatarOption(id: 'star', icon: Icons.star, color: Colors.deepPurple, label: 'Star'),
    AvatarOption(id: 'favorite', icon: Icons.favorite, color: Colors.pink, label: 'Heart'),
    AvatarOption(id: 'rocket_launch', icon: Icons.rocket_launch, color: Colors.deepOrange, label: 'Rocket'),
  ];

  @override
  void initState() {
    super.initState();

    // Pre-select if data exists
    if (widget.controller.userData['avatar'] != null) {
      _selectedAvatar = widget.controller.userData['avatar'];
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectAvatar(String id) {
    setState(() {
      _selectedAvatar = id;
    });
    // Trigger scale animation
    _animationController.forward(from: 0);
  }

  void _continue() {
    if (_selectedAvatar != null) {
      widget.controller.updateUserData({
        'avatar': _selectedAvatar,
      });
      widget.controller.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),

          // Emoji hero
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                '🎭',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'Choose your avatar',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Pick an icon that represents you',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 32),

          // Avatar grid
          Expanded(
            child: GridView.builder(
              itemCount: avatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                final isSelected = _selectedAvatar == avatar.id;

                return _buildAvatarCard(
                  context,
                  avatar: avatar,
                  isSelected: isSelected,
                  onTap: () => _selectAvatar(avatar.id),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedAvatar != null ? _continue : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _selectedAvatar == null ? 'Select an avatar' : 'Continue',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(
      BuildContext context, {
        required AvatarOption avatar,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              avatar.color.withValues(alpha: 0.8),
              avatar.color.withValues(alpha: 0.6),
            ],
          )
              : null,
          color: isSelected ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? avatar.color : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: avatar.color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ]
              : null,
        ),
        child: Stack(
          children: [
            // Avatar icon and label
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isSelected ? _scaleAnimation.value : 1.0,
                        child: Icon(
                          avatar.icon,
                          size: 48,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    avatar.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Check mark
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: avatar.color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AvatarOption {
  final String id;
  final IconData icon;
  final Color color;
  final String label;

  const AvatarOption({
    required this.id,
    required this.icon,
    required this.color,
    required this.label,
  });
}