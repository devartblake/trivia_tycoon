import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../core/services/settings/app_settings.dart';
import '../../core/services/auth_token_store.dart';
import '../../core/services/api_service.dart';
import '../providers/admin_auth_providers.dart';

/// Modern admin login dialog with server-based authentication.
class AdminLoginDialog extends ConsumerStatefulWidget {
  const AdminLoginDialog({super.key});

  @override
  ConsumerState<AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends ConsumerState<AdminLoginDialog>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _otpController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await _authenticateWithServer(_passwordController.text);

      if (!mounted) return;

      if (authenticated) {
        // Success - close dialog with success result
        Navigator.of(context).pop(true);
      } else {
        // Failed - show error and shake
        setState(() {
          _errorMessage = 'Invalid password. Please try again.';
          _isLoading = false;
        });
        _shakeController.forward(from: 0).then((_) => _shakeController.reset());
        _passwordController.clear();
      }
    } on ApiRequestException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapAuthError(e);
        _isLoading = false;
      });
      _shakeController.forward(from: 0).then((_) => _shakeController.reset());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Authentication failed: ${e.toString()}';
        _isLoading = false;
      });
      _shakeController.forward(from: 0).then((_) => _shakeController.reset());
    }
  }

  /// Server-based authentication and local role claim update.
  Future<bool> _authenticateWithServer(String password) async {
    final serviceManager = ref.read(serviceManagerProvider);
    final secureStorage = ref.read(secureStorageProvider);
    final email = await secureStorage.getSecret('user_email');

    if (email == null || email.isEmpty) {
      throw Exception('A logged-in user email is required for admin authentication.');
    }

    final payload = <String, dynamic>{
      'email': email,
      'password': password,
      if (_otpController.text.trim().isNotEmpty) 'otpCode': _otpController.text.trim(),
    };

    final response = await serviceManager.apiService.post(
      '/admin/auth/login',
      body: payload,
    );

    final success = response['success'] == true ||
        response['authenticated'] == true ||
        response.containsKey('accessToken') ||
        response.containsKey('access_token');
    if (!success) return false;

    final accessToken =
        response['accessToken']?.toString() ?? response['access_token']?.toString() ?? '';
    final refreshToken =
        response['refreshToken']?.toString() ?? response['refresh_token']?.toString() ?? '';
    final expiresIn = response['expiresIn'];
    DateTime? expiresAt;
    if (expiresIn is int) {
      expiresAt = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    }

    final admin = response['admin'];
    String? primaryRole;
    List<String> resolvedRoles = const ['admin'];
    List<String> permissions = const [];
    if (admin is Map<String, dynamic>) {
      final rolesRaw = admin['roles'];
      if (rolesRaw is List && rolesRaw.isNotEmpty) {
        primaryRole = rolesRaw.first.toString();
        resolvedRoles = rolesRaw.map((r) => r.toString()).toList();
      } else if (admin['role'] is String) {
        primaryRole = admin['role'] as String;
        resolvedRoles = [primaryRole!];
      }

      final perms = admin['permissions'];
      if (perms is List) {
        permissions = perms.map((p) => p.toString()).toList();
      }
    }
    primaryRole ??= 'admin';

    if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
      final tokenStore = ref.read(authTokenStoreProvider);
      await tokenStore.save(
        AuthSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAtUtc: expiresAt,
          userId: admin is Map<String, dynamic> ? admin['id']?.toString() : null,
          metadata: {
            'role': primaryRole,
            'roles': resolvedRoles,
            'permissions': permissions,
          },
        ),
      );
    }

    await serviceManager.playerProfileService.saveUserRole(primaryRole);
    await serviceManager.playerProfileService.saveUserRoles(resolvedRoles);
    await AppSettings.setString('userRole', primaryRole);
    await AppSettings.setAdminUser(primaryRole == 'admin');

    ref.invalidate(adminClaimsProvider);
    ref.invalidate(unifiedIsAdminProvider);

    return primaryRole == 'admin';
  }

  String _mapAuthError(ApiRequestException e) {
    switch (e.statusCode) {
      case 401:
        return 'Invalid credentials. Please verify your admin password.';
      case 403:
        return 'Your account does not have admin access.';
      case 429:
        return 'Too many attempts. Please try again in a moment.';
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: Container(
          width: size.width > 600 ? 400 : size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme),
              _buildForm(theme),
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Admin Access',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter password to continue',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_isLoading,
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter admin password',
                prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _otpController,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'OTP (optional)',
                hintText: 'Enter MFA code if required',
                prefixIcon: Icon(Icons.password_rounded, color: theme.primaryColor),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onFieldSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                disabledBackgroundColor: theme.primaryColor.withValues(alpha: 0.5),
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
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextButton.icon(
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
        icon: const Icon(Icons.close, size: 18),
        label: const Text('Cancel'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey[600],
        ),
      ),
    );
  }
}

/// Helper function to show the admin login dialog
Future<bool> showAdminLoginDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AdminLoginDialog(),
  );
  return result ?? false;
}
