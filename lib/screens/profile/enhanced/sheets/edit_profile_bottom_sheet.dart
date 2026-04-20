import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/settings/multi_profile_service.dart';
import '../../../../game/providers/profile_providers.dart';
import '../../../../game/providers/multi_profile_providers.dart';

/// Modern Edit Profile Bottom Sheet with Material 3 Design
///
/// Features:
/// - All profile fields editable
/// - Real-time validation
/// - Riverpod state management
/// - Success/error feedback
/// - Character counters
/// - Glassmorphism design
class EditProfileBottomSheet extends ConsumerStatefulWidget {
  final ProfileData profile;

  const EditProfileBottomSheet({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();

  /// Show the edit profile bottom sheet
  static Future<bool?> show(BuildContext context, ProfileData profile) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => EditProfileBottomSheet(profile: profile),
    );
  }
}

class _EditProfileBottomSheetState
    extends ConsumerState<EditProfileBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _gradeController;
  late TextEditingController _teamController;
  late TextEditingController _favoriteSubjectController;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _usernameController = TextEditingController(
      text: widget.profile.preferences['username'] ?? '',
    );
    _bioController = TextEditingController(
      text: widget.profile.preferences['bio'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.profile.country ?? '',
    );
    _gradeController = TextEditingController(
      text: widget.profile.ageGroup ?? '',
    );
    _teamController = TextEditingController(
      text: widget.profile.preferences['teamName'] ?? 'Study Squad',
    );
    _favoriteSubjectController = TextEditingController(
      text: widget.profile.preferences['favoriteSubject'] ?? '',
    );

    // Track changes
    _nameController.addListener(_onFieldChanged);
    _usernameController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
    _gradeController.addListener(_onFieldChanged);
    _teamController.addListener(_onFieldChanged);
    _favoriteSubjectController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _gradeController.dispose();
    _teamController.dispose();
    _favoriteSubjectController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  String _normalizeUsername(String raw) {
    final normalized = raw
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return normalized;
  }

  String _usernameFromDisplayName(String displayName) {
    final generated = _normalizeUsername(displayName);
    return generated.isEmpty ? 'player' : generated;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final multiProfileService = ref.read(multiProfileServiceProvider);
      final displayName = _nameController.text.trim();
      final manualUsername = _normalizeUsername(_usernameController.text);
      final finalUsername = manualUsername.isNotEmpty
          ? manualUsername
          : _usernameFromDisplayName(displayName);

      final success = await multiProfileService.updateProfile(
        widget.profile.id,
        name: displayName,
        country: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        ageGroup: _gradeController.text.trim().isNotEmpty
            ? _gradeController.text.trim()
            : null,
        preferences: {
          ...widget.profile.preferences,
          'username': finalUsername,
          'bio': _bioController.text.trim(),
          'teamName': _teamController.text.trim(),
          'favoriteSubject': _favoriteSubjectController.text.trim(),
        },
      );

      if (mounted) {
        if (success) {
          var loadoutSynced = true;
          try {
            await ref.read(backendProfileSocialServiceProvider).saveLoadout({
              'username': finalUsername,
              'bio': _bioController.text.trim(),
              'teamName': _teamController.text.trim(),
              'favoriteSubject': _favoriteSubjectController.text.trim(),
            });
            ref.invalidate(profileLoadoutProvider);
          } catch (_) {
            loadoutSynced = false;
          }

          // Refresh the profile data
          ref.read(profileManagerProvider.notifier).refreshProfiles();

          // Show success message
          if (loadoutSynced) {
            _showSuccessSnackBar('Profile updated successfully!');
          } else {
            _showWarningSnackBar(
              'Profile updated locally. Backend loadout sync is still pending.',
            );
          }

          // Close the bottom sheet with success result
          Navigator.of(context).pop(true);
        } else {
          _showErrorSnackBar('Failed to update profile. Please try again.');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A24),
            const Color(0xFF0A0A0F),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main Content
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildForm(),
              ),
            ],
          ),

          // Loading Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A24),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Saving profile...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title with Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_hasChanges && !_isLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFBBF24),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Unsaved',
                        style: TextStyle(
                          color: const Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Display Name',
            icon: Icons.person_rounded,
            maxLength: 30,
            required: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.alternate_email_rounded,
            maxLength: 20,
            prefix: '@',
            hint: 'your_username',
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                  return 'Only letters, numbers, and underscores allowed';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bioController,
            label: 'Bio',
            icon: Icons.info_rounded,
            maxLength: 150,
            maxLines: 3,
            hint: 'Tell us about yourself...',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _locationController,
            label: 'Location',
            icon: Icons.location_on_rounded,
            maxLength: 50,
            hint: 'City, Country',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _gradeController,
            label: 'Current Grade / Education Level',
            icon: Icons.school_rounded,
            maxLength: 20,
            hint: 'e.g., 10th Grade, University',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _favoriteSubjectController,
            label: 'Favorite Subject',
            icon: Icons.favorite_rounded,
            maxLength: 30,
            hint: 'e.g., Science, Math, History',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _teamController,
            label: 'Study Group / Team Name',
            icon: Icons.group_rounded,
            maxLength: 30,
            hint: 'e.g., Study Squad, Math Masters',
          ),
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
    int maxLines = 1,
    String? hint,
    String? prefix,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          maxLength: maxLength,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
            prefixText: prefix,
            prefixStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
            fillColor: Colors.white.withValues(alpha: 0.05),
            filled: true,
            counterStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                _isLoading ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildSaveButton(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _saveProfile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: _isLoading
                ? LinearGradient(
                    colors: [
                      Colors.grey.shade700,
                      Colors.grey.shade600,
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isLoading
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Text(
                _isLoading ? 'Saving...' : 'Save Changes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
