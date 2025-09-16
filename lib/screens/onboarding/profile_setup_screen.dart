import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/extensions/player_profile_extensions.dart';
import '../../game/providers/provider_bridge.dart';
import '../../game/providers/riverpod_providers.dart';

/// Profile setup screen for username, avatar selection, and additional settings
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  String? _selectedAvatarId;
  bool _isLoading = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAvatarId == null) {
      _showSnackBar('Please select an avatar');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save profile data using the extension method for cleaner code
      final playerProfileService = ref.read(playerProfileServiceProvider);

      // Use the extension method to save onboarding profile data
      await playerProfileService.saveOnboardingProfile(
        playerName: _usernameController.text.trim(),
        avatar: _selectedAvatarId!,
      );

      // Mark profile setup as completed using the bridge
      await ref.read(providerBridgeStateProvider.notifier).completeOnboarding();

      // Navigate to main app
      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      _showSnackBar('Failed to save profile: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Allow going back to intro
            context.go('/intro');
          },
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome text
                    Text(
                      'Let\'s get you set up!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Choose your username and avatar to get started.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Username section
                    _buildUsernameSection(),

                    const SizedBox(height: 32),

                    // Avatar selection section
                    _buildAvatarSection(),

                    const SizedBox(height: 48),

                    // Complete button
                    _buildCompleteButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: 'Enter your username',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Username is required';
            }
            if (value.trim().length < 3) {
              return 'Username must be at least 3 characters';
            }
            if (value.trim().length > 20) {
              return 'Username must be less than 20 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Avatar',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        // Avatar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _avatarOptions.length,
          itemBuilder: (context, index) {
            final avatar = _avatarOptions[index];
            final isSelected = _selectedAvatarId == avatar.id;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatarId = avatar.id;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      avatar.icon,
                      size: 32,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      avatar.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _completeSetup,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Complete Setup',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Avatar option model
class AvatarOption {
  final String id;
  final String name;
  final IconData icon;

  const AvatarOption({
    required this.id,
    required this.name,
    required this.icon,
  });
}

/// Available avatar options
final List<AvatarOption> _avatarOptions = [
  const AvatarOption(id: 'rocket', name: 'Rocket', icon: Icons.rocket_launch),
  const AvatarOption(id: 'star', name: 'Star', icon: Icons.star),
  const AvatarOption(id: 'lightning', name: 'Lightning', icon: Icons.flash_on),
  const AvatarOption(id: 'crown', name: 'Crown', icon: Icons.emoji_events),
  const AvatarOption(id: 'fire', name: 'Fire', icon: Icons.local_fire_department),
  const AvatarOption(id: 'diamond', name: 'Diamond', icon: Icons.diamond),
  const AvatarOption(id: 'brain', name: 'Brain', icon: Icons.psychology),
  const AvatarOption(id: 'shield', name: 'Shield', icon: Icons.shield),
  const AvatarOption(id: 'magic', name: 'Magic', icon: Icons.auto_fix_high),
  const AvatarOption(id: 'heart', name: 'Heart', icon: Icons.favorite),
  const AvatarOption(id: 'music', name: 'Music', icon: Icons.music_note),
  const AvatarOption(id: 'game', name: 'Game', icon: Icons.sports_esports),
];