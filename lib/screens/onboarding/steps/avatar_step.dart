import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';
import '../../../screens/menu/layouts/responsive_builder.dart';
import '../widgets/onboarding_step_shell.dart';

class AvatarStep extends StatefulWidget {
  final ModernOnboardingController controller;

  const AvatarStep({super.key, required this.controller});

  @override
  State<AvatarStep> createState() => _AvatarStepState();
}

class _AvatarStepState extends State<AvatarStep>
    with SingleTickerProviderStateMixin {
  String? _selectedAvatar;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  final List<AvatarOption> avatars = [
    AvatarOption(
      id: 'avatar-1',
      imagePath: 'assets/images/avatars/avatar-1.png',
      color: Colors.blue,
      label: 'Explorer',
    ),
    AvatarOption(
      id: 'avatar-2',
      imagePath: 'assets/images/avatars/avatar-2.png',
      color: Colors.green,
      label: 'Scholar',
    ),
    AvatarOption(
      id: 'avatar-3',
      imagePath: 'assets/images/avatars/avatar-3.png',
      color: Colors.purple,
      label: 'Champion',
    ),
    AvatarOption(
      id: 'avatar-4',
      imagePath: 'assets/images/avatars/avatar-4.png',
      color: Colors.orange,
      label: 'Adventurer',
    ),
    AvatarOption(
      id: 'avatar-5',
      imagePath: 'assets/images/avatars/avatar-5.png',
      color: Colors.teal,
      label: 'Brainy',
    ),
    AvatarOption(
      id: 'monster_1',
      imagePath: 'assets/avatarPackages/monster_avatars_1.0.0/monster_1.png',
      color: Colors.red,
      label: 'Monster',
    ),
    AvatarOption(
      id: 'monster_2',
      imagePath: 'assets/avatarPackages/monster_avatars_1.0.0/monster_2.png',
      color: Colors.deepOrange,
      label: 'Brute',
    ),
    AvatarOption(
      id: 'monster_3',
      imagePath: 'assets/avatarPackages/monster_avatars_1.0.0/monster_3.png',
      color: Colors.indigo,
      label: 'Titan',
    ),
    AvatarOption(
      id: 'monster_4',
      imagePath: 'assets/avatarPackages/monster_avatars_1.0.0/monster_4.png',
      color: Colors.brown,
      label: 'Golem',
    ),
    AvatarOption(
      id: 'monster_5',
      imagePath: 'assets/avatarPackages/monster_avatars_1.0.0/monster_5.png',
      color: Colors.deepPurple,
      label: 'Phantom',
    ),
    AvatarOption(
      id: 'cyclops_1',
      imagePath: 'assets/avatarPackages/monster_avatars_1.0.0/cyclops_1.png',
      color: Colors.cyan,
      label: 'Cyclops',
    ),
    AvatarOption(
      id: 'triclops_1',
      imagePath: 'assets/avatarPackages/monster_avatars_1.0.0/triclops_1.png',
      color: Colors.lime,
      label: 'Triclops',
    ),
  ];

  @override
  void initState() {
    super.initState();
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
    _animationController.forward(from: 0);
  }

  void _continue() {
    if (_selectedAvatar != null) {
      // Store the imagePath so it can be synced to the backend
      final selected = avatars.firstWhere((a) => a.id == _selectedAvatar);
      widget.controller.updateUserData({
        'avatar': selected.imagePath,
      });
      widget.controller.nextStep();
    }
  }

  AvatarOption? get _selectedOption =>
      _selectedAvatar != null
          ? avatars.firstWhere(
              (a) => a.id == _selectedAvatar,
              orElse: () => avatars.first,
            )
          : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = isMobileLayout(context);

    final hero = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text('🎭', style: TextStyle(fontSize: 40)),
      ),
    );

    final panelIllustration = _buildPanelPreview(context);

    final grid = _buildGrid(context, isMobile);

    final footer = SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _selectedAvatar != null ? _continue : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          _selectedAvatar == null ? 'Select an avatar' : 'Continue',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );

    return OnboardingStepShell(
      hero: hero,
      title: 'Choose your avatar',
      subtitle: 'Pick an image that represents you',
      panelIllustration: panelIllustration,
      footer: footer,
      child: grid,
    );
  }

  Widget _buildPanelPreview(BuildContext context) {
    final theme = Theme.of(context);
    final option = _selectedOption;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: option != null
              ? ClipRRect(
                  key: ValueKey(option.id),
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    option.imagePath,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      size: 120,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 120,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
        ),
        if (option != null) ...[
          const SizedBox(height: 16),
          Text(
            option.label,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGrid(BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 1024 ? 5 : (w >= 768 ? 4 : 3);
        return GridView.builder(
          itemCount: avatars.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final avatar = avatars[index];
            final isSelected = _selectedAvatar == avatar.id;
            return _buildAvatarCard(context, avatar: avatar, isSelected: isSelected);
          },
        );
      },
    );
  }

  Widget _buildAvatarCard(
    BuildContext context, {
    required AvatarOption avatar,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _selectAvatar(avatar.id),
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: isSelected ? _scaleAnimation.value : 1.0,
                      child: child,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        avatar.imagePath,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          size: 48,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    avatar.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 14, color: avatar.color),
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
  final String imagePath;
  final Color color;
  final String label;

  const AvatarOption({
    required this.id,
    required this.imagePath,
    required this.color,
    required this.label,
  });
}
