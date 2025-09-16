import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/auth_providers.dart';
import '../state/admin_provider.dart';

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

    // Check if user is logged in first
    if (!authState.isLoggedIn) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Access denied. Please log in.'),
            ],
          ),
        ),
      );
    }

    // Check admin access
    return adminAccess.when(
      data: (hasAccess) {
        if (hasAccess) {
          return child;
        } else {
          return _buildAccessDeniedScreen(context, routeName);
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
      error: (error, stack) => _buildErrorScreen(context, error.toString()),
    );
  }

  Widget _buildAccessDeniedScreen(BuildContext context, String routeName) {
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
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 80,
                color: Colors.red.shade400,
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
                'You need administrator privileges to access "$routeName".',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Contact your system administrator if you believe this is an error.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/main'),
                    icon: const Icon(Icons.home),
                    label: const Text('Go Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/settings'),
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
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
                onPressed: () => context.go('/main'),
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
