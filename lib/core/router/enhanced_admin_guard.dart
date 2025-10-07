import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/dialogs/admin_login_dialog.dart';
import '../../game/providers/auth_providers.dart';
import '../state/admin_provider.dart';

/// Provider to track navigation attempts to admin routes
final adminNavigationAttemptsProvider = StateProvider<int>((ref) => 0);

/// Provider to track lock icon clicks
final lockIconClicksProvider = StateProvider<int>((ref) => 0);

/// Enhanced admin guard that uses providers for admin access control
String? enhancedAdminGuard(BuildContext context, GoRouterState state) {
  // This is a simplified version for the guard function
  // The actual admin access check is handled in the route builder
  return null;
}

/// Widget that wraps admin routes with proper access control
class AdminRouteWrapper extends ConsumerWidget {
  final Widget child;
  final String routeName;

  const AdminRouteWrapper({
    super.key,
    required this.child,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final adminAccess = ref.watch(adminAccessProvider);

    // Increment navigation attempts when this widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminNavigationAttemptsProvider.notifier).update((state) => state + 1);
    });

    // Check if user is logged in first
    if (!authState.isLoggedIn) {
      return _buildLoginRequiredScreen(context, ref);
    }

    // Check admin access
    return adminAccess.when(
      data: (hasAccess) {
        if (hasAccess) {
          return child;
        } else {
          return _AdminAccessPrompt(
            routeName: routeName,
            child: child,
          );
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking admin access...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => _buildErrorScreen(context, error.toString(), ref),
    );
  }

  Widget _buildLoginRequiredScreen(BuildContext context, WidgetRef ref) {
    // Use the same interactive prompt even when not logged in
    return _AdminAccessPrompt(
      routeName: routeName,
      requiresLogin: true,
      child: child,
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.orange.shade400,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Access Check Failed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.orange.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to verify admin access: $error',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(adminNavigationAttemptsProvider.notifier).state = 0;
                  ref.read(lockIconClicksProvider.notifier).state = 0;
                  context.go('/main');
                },
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal widget that prompts for admin login when access is denied
class _AdminAccessPrompt extends ConsumerStatefulWidget {
  final String routeName;
  final Widget child;
  final bool requiresLogin;

  const _AdminAccessPrompt({
    required this.routeName,
    required this.child,
    this.requiresLogin = false,
  });

  @override
  ConsumerState<_AdminAccessPrompt> createState() => _AdminAccessPromptState();
}

class _AdminAccessPromptState extends ConsumerState<_AdminAccessPrompt> {
  bool _hasAdminAccess = false;
  bool _isHovering = false;

  @override
  void dispose() {
    // Reset counters when this screen is disposed (user navigated away)
    if (!_hasAdminAccess) {
      ref.read(adminNavigationAttemptsProvider.notifier).state = 0;
      ref.read(lockIconClicksProvider.notifier).state = 0;
    }
    super.dispose();
  }

  Future<void> _handleLockIconInteraction() async {
    final navigationAttempts = ref.read(adminNavigationAttemptsProvider);
    final currentClicks = ref.read(lockIconClicksProvider);

    // Increment click counter
    ref.read(lockIconClicksProvider.notifier).update((state) => state + 1);
    final newClicks = currentClicks + 1;

    // Check if both conditions are met: 2+ navigation attempts AND 2+ lock clicks
    if (navigationAttempts >= 2 && newClicks >= 2) {
      await _promptForAdminLogin();
    } else {
      // Show feedback about progress
      final navProgress = navigationAttempts >= 2 ? '✓' : '$navigationAttempts/2';
      final clickProgress = newClicks >= 2 ? '✓' : '$newClicks/2';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Progress: Navigate $navProgress • Click lock $clickProgress',
              textAlign: TextAlign.center,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.grey[800],
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _promptForAdminLogin() async {
    final authenticated = await showAdminLoginDialog(context);

    if (!mounted) return;

    if (authenticated) {
      setState(() {
        _hasAdminAccess = true;
      });

      // Reset counters on successful login
      ref.read(adminNavigationAttemptsProvider.notifier).state = 0;
      ref.read(lockIconClicksProvider.notifier).state = 0;

      // TODO: Update admin provider state
      // ref.read(adminAccessProvider.notifier).grantTemporaryAccess();
    } else {
      // User cancelled - don't reset counters, they can try again
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login cancelled'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAdminAccess) {
      return widget.child;
    }

    return _buildAccessDeniedScreen(context);
  }

  Widget _buildAccessDeniedScreen(BuildContext context) {
    final navigationAttempts = ref.watch(adminNavigationAttemptsProvider);
    final lockClicks = ref.watch(lockIconClicksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Interactive lock icon
              MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _handleLockIconInteraction,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isHovering
                          ? theme.primaryColor.withOpacity(0.1)
                          : Colors.red.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isHovering
                            ? theme.primaryColor
                            : Colors.red.shade400,
                        width: 2,
                      ),
                      boxShadow: _isHovering ? [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ] : [],
                    ),
                    child: Icon(
                      _isHovering ? Icons.lock_open : Icons.admin_panel_settings_outlined,
                      size: 80,
                      color: _isHovering
                          ? theme.primaryColor
                          : Colors.red.shade400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Admin Access Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You need administrator privileges to access "${widget.routeName}".',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try tapping the lock icon above...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Progress indicators
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    _buildProgressRow(
                      'Navigation Attempts',
                      navigationAttempts,
                      1,
                      Icons.route,
                    ),
                    const SizedBox(height: 12),
                    _buildProgressRow(
                      'Lock Icon Clicks',
                      lockClicks,
                      3,
                      Icons.touch_app,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(adminNavigationAttemptsProvider.notifier).state = 0;
                      ref.read(lockIconClicksProvider.notifier).state = 0;
                      context.go('/main');
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Go Home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int current, int required, IconData icon) {
    final isComplete = current >= required;
    final color = isComplete ? Colors.green : Colors.grey;

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: (current / required).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            isComplete ? '✓' : '$current/$required',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper function to create admin routes with proper wrapper
GoRoute createAdminRoute({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
  String? name,
}) {
  return GoRoute(
    path: path,
    name: name,
    builder: (context, state) {
      final screen = builder(context, state);
      return AdminRouteWrapper(
        routeName: name ?? path,
        child: screen,
      );
    },
  );
}