import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../ui_components/login/trivia_login.dart';
import '../core/constants/image_strings.dart';
import '../game/providers/auth_providers.dart';
import '../game/providers/onboarding_providers.dart';
import 'onboarding/widget/constants.dart';

/// Updated login screen that integrates with new flow
class LoginScreen extends ConsumerWidget {
  static const routeName = '/auth';
  const LoginScreen({super.key});

  static const mockUsers = {
    'dribbble@gmail.com': '12345',
    'hunter@gmail.com': 'hunter',
    'near.huscarl@gmail.com': 'subscribe to pewdiepie',
    '@.com': '.',
  };

  Duration get loginTime => Duration(milliseconds: timeDilation.ceil() * 2250);

  Future<String?> _loginUser(LoginData data, WidgetRef ref) async {
    // Simulate mock logic
    await Future.delayed(loginTime);
    if (!mockUsers.containsKey(data.name)) return 'User does not exist';
    if (mockUsers[data.name] != data.password) return 'Incorrect password';

    try {
      // Get services
      final authOps = ref.read(authOperationsProvider);
      final profileService = ref.read(playerProfileServiceProvider);
      final onboardingService = ref.read(onboardingSettingsServiceProvider);

      // Perform login using the auth operations
      await authOps.login(data.name);

      // Save additional profile data
      await profileService.saveUserRoles(['player']);

      // Check if user has completed onboarding before
      final hasOnboarded = await onboardingService.hasCompletedOnboarding();

      if (hasOnboarded) {
        // Returning user - set onboarding flags to completed
        ref.read(hasSeenIntroProvider.notifier).state = true;
        ref.read(hasCompletedProfileProvider.notifier).state = true;

        // Load user profile data for returning user
        final playerName = await profileService.getPlayerName();
        final userRole = await profileService.getUserRole();
        debugPrint('Loaded profile for returning user: $playerName, role: $userRole');
      }
      // If not onboarded, leave flags as false - router will redirect to intro

      return null; // Success triggers navigation
    } catch (e) {
      return 'Login failed: ${e.toString()}';
    }
  }

  Future<String?> _signupUser(SignupData data, WidgetRef ref) async {
    try {
      // Simulate server-side processing delay
      await Future.delayed(loginTime);

      // Extract from signup form
      final email = data.name;
      final username = data.additionalSignupData?['Username'] ?? 'Player';
      final name = data.additionalSignupData?['Name'] ?? '';
      final phone = data.additionalSignupData?['phone_number'] ?? '';

      // Get services
      final authOps = ref.read(authOperationsProvider);
      final playerProfileService = ref.read(playerProfileServiceProvider);
      final authService = ref.read(authServiceProvider);
      final onboardingService = ref.read(onboardingSettingsServiceProvider);

      // Perform login using the auth operations
      await authOps.login(email!);

      // Assign role and optional premium flag
      const defaultRole = 'player';
      final isPremium = data.additionalSignupData?['isPremiumUser'] == 'true';

      // Save profile info
      await playerProfileService.savePlayerName(username);
      await playerProfileService.saveUserRole(defaultRole);
      await playerProfileService.saveUserRoles([defaultRole]);
      await playerProfileService.setPremiumStatus(isPremium);

      // Optionally save more fields
      if (name.isNotEmpty) await playerProfileService.saveAvatar(name);
      if (phone.isNotEmpty) await authService.secureStorage.setSecret('phone_number', phone);

      // Save email and onboarding flag
      if (email != null) await authService.secureStorage.setUserEmail(email);
      await onboardingService.setHasCompletedOnboarding(false);

      // For new signups, onboarding flags remain false
      // Router will redirect to intro automatically

      return null; // Success
    } catch (e) {
      return 'Signup failed: ${e.toString()}';
    }
  }

  Future<String?> _recoverPassword(String name) async {
    await Future.delayed(loginTime);
    if (!mockUsers.containsKey(name)) return 'User not exists';
    return null;
  }

  Future<String?> _signupConfirm(String error, LoginData data) async {
    await Future.delayed(loginTime);
    return null;
  }

  Future<LoginMessages> getLoginMessages(BuildContext context) async {
    return LoginMessages(
      userHint: 'Email',
      passwordHint: 'Password',
      confirmPasswordHint: 'Confirm Password',
      loginButton: 'LOG IN',
      signupButton: 'REGISTER',
      forgotPasswordButton: 'Forgot Password?',
      recoverPasswordButton: 'RECOVER',
      goBackButton: 'GO BACK',
      confirmPasswordError: 'Passwords don\'t match!',
      recoverPasswordIntro: 'Don\'t worry, it happens to everyone.',
      recoverPasswordDescription: 'Enter your email address and we\'ll send you a link to reset your password.',
      recoverPasswordSuccess: 'Password reset link sent successfully!',
      tycoonToastTitleError: 'Oops!',
      tycoonToastTitleSuccess: 'Success!',
      providersTitleFirst: 'or sign in with',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<LoginMessages>(
      future: getLoginMessages(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return FlutterLogin(
          title: Constants.appName,
          logo: const AssetImage(tTriviaGameImage),
          logoTag: Constants.logoTag,
          titleTag: Constants.titleTag,
          navigateBackAfterRecovery: true,
          onConfirmRecover: _signupConfirm,
          onConfirmSignup: _signupConfirm,
          loginAfterSignUp: false,

          // Social login providers
          loginProviders: [
            LoginProvider(
              button: Buttons.linkedIn,
              label: 'Sign in with LinkedIn',
              callback: () async {
                return null;
              },
              providerNeedsSignUpCallback: () => Future.value(true),
            ),
            LoginProvider(
              icon: FontAwesomeIcons.google,
              label: 'Google',
              callback: () async {
                return null;
              },
            ),
            LoginProvider(
              icon: FontAwesomeIcons.githubAlt,
              callback: () async {
                debugPrint('GitHub sign in initiated');
                await Future.delayed(loginTime);
                return null;
              },
            ),
          ],

          // Enhanced theme
          theme: LoginTheme(
            primaryColor: Theme.of(context).primaryColor,
            accentColor: Theme.of(context).primaryColor.withOpacity(0.8),
            errorColor: Colors.redAccent,
            pageColorLight: Theme.of(context).primaryColor.withOpacity(0.1),
            pageColorDark: Theme.of(context).primaryColor.withOpacity(0.3),
            logoWidth: 0.80,
            titleStyle: TextStyle(
              color: Theme.of(context).primaryColor,
              fontFamily: 'Quicksand',
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
            bodyStyle: const TextStyle(
              fontStyle: FontStyle.normal,
              color: Colors.black87,
            ),
            textFieldStyle: const TextStyle(
              color: Colors.black87,
            ),
            buttonStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            cardTheme: CardTheme(
              color: Colors.white,
              elevation: 8,
              margin: const EdgeInsets.only(top: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            buttonTheme: LoginButtonTheme(
              splashColor: Theme.of(context).primaryColor.withOpacity(0.3),
              backgroundColor: Theme.of(context).primaryColor,
              highlightColor: Theme.of(context).primaryColor.withOpacity(0.8),
              elevation: 4.0,
              highlightElevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Validation
          userValidator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
          passwordValidator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 3) {
              return 'Password must be at least 3 characters';
            }
            return null;
          },

          // Callbacks
          onLogin: (data) => _loginUser(data, ref),
          onSignup: (data) => _signupUser(data, ref),
          onRecoverPassword: _recoverPassword,

          // Navigation after successful auth
          onSubmitAnimationCompleted: () {
            // Don't navigate manually - let the router redirect logic handle it
            // The router will check auth state and onboarding flags to decide where to go
          },

          // Additional signup fields
          additionalSignupFields: const [
            UserFormField(
              keyName: 'Username',
              icon: Icon(FontAwesomeIcons.userLarge),
              displayName: 'Username',
            ),
            UserFormField(
              keyName: 'Name',
              displayName: 'Full Name',
            ),
            UserFormField(
              keyName: 'phone_number',
              displayName: 'Phone Number',
              userType: LoginUserType.phone,
            ),
          ],

          // Header widget
          headerWidget: const AuthHeaderWidget(),

          // Footer text (FlutterLogin only accepts String for footer)
          footer: 'New to Trivia Tycoon? Create an account to get started!',
        );
      },
    );
  }
}

/// Header widget for auth screens
class AuthHeaderWidget extends StatelessWidget {
  const AuthHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: "Welcome to "),
              TextSpan(
                text: "Trivia Tycoon",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Master every question, become the ultimate tycoon',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Row(
          children: <Widget>[
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Sign In"),
            ),
            Expanded(child: Divider()),
          ],
        ),
      ],
    );
  }
}
