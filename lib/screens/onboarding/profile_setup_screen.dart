import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/providers/multi_profile_providers.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart';

// Import the tempSignupDataProvider
final tempSignupDataProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Unified Profile setup screen that handles both new profiles and migration
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  String? _selectedAvatarPath;
  String? _selectedAgeGroup = 'teens';
  String? _selectedCountry;
  bool _isLoading = false;
  bool _isInitializing = true;

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

    _initializeProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize profile - check if we need to migrate existing data or create new
  Future<void> _initializeProfile() async {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final multiProfileService = ref.read(multiProfileServiceProvider);

      // Check if we already have profiles in the multi-profile system
      final existingProfiles = await multiProfileService.getAllProfiles();

      if (existingProfiles.isNotEmpty) {
        // User already has profiles, redirect to profile selection
        if (mounted) {
          context.go('/profile-selection');
          return;
        }
      }

      // Check for temporary signup data first
      final tempSignupData = ref.read(tempSignupDataProvider);
      if (tempSignupData != null) {
        // Use signup data
        _usernameController.text = tempSignupData['username'] ?? '';
        // Clear temp data after using it
        ref.read(tempSignupDataProvider.notifier).state = null;
      } else {
        // Check for existing profile data to migrate
        final playerProfileService = serviceManager.playerProfileService;
        final existingName = await playerProfileService.getPlayerName();
        final existingAvatar = await playerProfileService.getAvatar();
        final existingCountry = await playerProfileService.getCountry();
        final existingAgeGroup = await playerProfileService.getAgeGroup();

        // Pre-fill form with existing data if available
        if (existingName != 'Player' && existingName.isNotEmpty) {
          _usernameController.text = existingName;
        }

        if (existingAvatar != null && existingAvatar.isNotEmpty) {
          _selectedAvatarPath = existingAvatar;
        }

        if (existingCountry != null && existingCountry.isNotEmpty) {
          _selectedCountry = existingCountry;
        }

        if (existingAgeGroup != null && existingAgeGroup.isNotEmpty) {
          _selectedAgeGroup = existingAgeGroup;
        }
      }

      setState(() {
        _isInitializing = false;
      });

      _animationController.forward();
    } catch (e) {
      debugPrint('Error initializing profile: $e');
      setState(() {
        _isInitializing = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final multiProfileService = ref.read(multiProfileServiceProvider);
      final serviceManager = ref.read(serviceManagerProvider);

      // Create the first profile in the multi-profile system
      final newProfile = await multiProfileService.createProfile(
        name: _usernameController.text.trim(),
        avatar: _selectedAvatarPath,
        ageGroup: _selectedAgeGroup,
        country: _selectedCountry,
      );

      if (newProfile != null) {
        // Set this as the active profile
        await multiProfileService.setActiveProfile(newProfile.id);

        // Update the active profile state provider
        ref.read(activeProfileStateProvider.notifier).state = newProfile;

        // Mark onboarding as complete in all systems
        await serviceManager.onboardingSettingsService.setOnboardingCompleted(true);
        await serviceManager.onboardingSettingsService.setHasCompletedOnboarding(true);

        // Update Riverpod onboarding state
        ref.read(hasSeenIntroProvider.notifier).state = true;
        ref.read(hasCompletedProfileProvider.notifier).state = true;

        // Also save in the legacy system for backward compatibility
        final playerProfileService = serviceManager.playerProfileService;
        await playerProfileService.savePlayerName(newProfile.name);
        if (newProfile.avatar != null) {
          await playerProfileService.saveAvatar(newProfile.avatar!);
        }
        if (newProfile.country != null) {
          await playerProfileService.saveCountry(newProfile.country!);
        }
        if (newProfile.ageGroup != null) {
          await playerProfileService.saveAgeGroup(newProfile.ageGroup!);
        }

        // Navigate to main app
        if (mounted) {
          context.go('/');
        }
      } else {
        _showSnackBar('Failed to create profile. Please try again.');
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

    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Setting up your profile...',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
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
                    _buildUsernameSection(),
                    const SizedBox(height: 32),
                    _buildAgeGroupSection(),
                    const SizedBox(height: 32),
                    _buildCountrySection(),
                    const SizedBox(height: 32),
                    _buildAvatarSection(),
                    const SizedBox(height: 48),
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

  Widget _buildAgeGroupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Age Group',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: ['kids', 'teens', 'adults'].map((group) {
            final isSelected = _selectedAgeGroup == group;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedAgeGroup = group),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    group.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCountrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          decoration: InputDecoration(
            hintText: 'Select your country',
            prefixIcon: const Icon(Icons.public),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _countries.map((country) {
            return DropdownMenuItem(
              value: country,
              child: Text(country),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCountry = value),
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: _avatarOptions.length,
          itemBuilder: (context, index) {
            final avatar = _avatarOptions[index];
            final isSelected = _selectedAvatarPath == avatar.path;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatarPath = avatar.path;
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
                    if (avatar.path != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          avatar.path!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              avatar.icon,
                              size: 32,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                            );
                          },
                        ),
                      )
                    else
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
                      textAlign: TextAlign.center,
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
  final String name;
  final IconData icon;
  final String? path;

  const AvatarOption({
    required this.name,
    required this.icon,
    this.path,
  });
}

/// Available avatar options with real asset paths
final List<AvatarOption> _avatarOptions = [
  const AvatarOption(
    name: 'Avatar 1',
    icon: Icons.person,
    path: 'assets/images/avatars/avatar-1.png',
  ),
  const AvatarOption(
    name: 'Avatar 2',
    icon: Icons.person,
    path: 'assets/images/avatars/avatar-2.png',
  ),
  const AvatarOption(
    name: 'Avatar 3',
    icon: Icons.person,
    path: 'assets/images/avatars/avatar-3.png',
  ),
  const AvatarOption(
    name: 'Avatar 4',
    icon: Icons.person,
    path: 'assets/images/avatars/avatar-4.png',
  ),
  const AvatarOption(
    name: 'Avatar 5',
    icon: Icons.person,
    path: 'assets/images/avatars/avatar-5.png',
  ),
  const AvatarOption(name: 'Rocket', icon: Icons.rocket_launch),
  const AvatarOption(name: 'Star', icon: Icons.star),
  const AvatarOption(name: 'Lightning', icon: Icons.flash_on),
  const AvatarOption(name: 'Crown', icon: Icons.emoji_events),
  const AvatarOption(name: 'Fire', icon: Icons.local_fire_department),
  const AvatarOption(name: 'Diamond', icon: Icons.diamond),
  const AvatarOption(name: 'Brain', icon: Icons.psychology),
];

/// Common countries list
final List<String> _countries = [
  'United States',
  'Canada',
  'United Kingdom',
  'Australia',
  'Germany',
  'France',
  'Spain',
  'Italy',
  'Japan',
  'South Korea',
  'Brazil',
  'Mexico',
  'India',
  'China',
  'Other',
];
