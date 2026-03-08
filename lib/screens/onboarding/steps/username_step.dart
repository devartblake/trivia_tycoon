import 'package:flutter/material.dart';
import '../../../game/controllers/onboarding_controller.dart';

class UsernameStep extends StatefulWidget {
  final ModernOnboardingController controller;

  const UsernameStep({
    super.key,
    required this.controller,
  });

  @override
  State<UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends State<UsernameStep> {
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if data exists
    if (widget.controller.userData['username'] != null) {
      _usernameController.text = widget.controller.userData['username'];
      _validateUsername(_usernameController.text);
    }
    _usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    _validateUsername(_usernameController.text);
  }

  void _validateUsername(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorText = null;
        _isValid = false;
      } else if (value.length < 3) {
        _errorText = 'Username must be at least 3 characters';
        _isValid = false;
      } else if (value.length > 20) {
        _errorText = 'Username must be less than 20 characters';
        _isValid = false;
      } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
        _errorText = 'Only letters, numbers, and underscores allowed';
        _isValid = false;
      } else {
        _errorText = null;
        _isValid = true;
      }
    });
  }

  void _continue() {
    if (_isValid) {
      widget.controller.updateUserData({
        'username': _usernameController.text.trim(),
      });
      widget.controller.nextStep();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _focusNode.dispose();
    super.dispose();
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
            child: Center(
              child: Text(
                '👋',
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'What should we call you?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Choose a unique username for your profile',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 32),

          // Username input
          TextField(
            controller: _usernameController,
            focusNode: _focusNode,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _continue(),
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'e.g., TriviaChamp_42',
              errorText: _errorText,
              prefixIcon: const Icon(Icons.person_outline),
              suffixIcon: _isValid
                  ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Helper text
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '3-20 characters, letters, numbers, and underscores only',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isValid ? _continue : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Continue',
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
}