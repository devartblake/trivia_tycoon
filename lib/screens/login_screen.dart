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
import '../game/providers/multi_profile_providers.dart';
import 'onboarding/widget/constants.dart';

/// Updated login screen that integrates with multi-profile system
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
    await Future.delayed(loginTime);
    if (!mockUsers.containsKey(data.name)) return 'User does not exist';
    if (mockUsers[data.name] != data.password) return 'Incorrect password';

    try {
      // Get services
      final authOps = ref.read(authOperationsProvider);
      final multiProfileService = ref.read(multiProfileServiceProvider);
      final serviceManager = ref.read(serviceManagerProvider);

      // Perform login using the auth operations
      await authOps.login(data.name);

      // Check if user has profiles in the multi-profile system
      final existingProfiles = await multiProfileService.getAllProfiles();

      if (existingProfiles.isNotEmpty) {
        // User has existing profiles - set up active profile and navigate
        final activeProfile = await multiProfileService.getActiveProfile();

        if (activeProfile != null) {
          // Update the active profile state
          ref.read(activeProfileStateProvider.notifier).state = activeProfile;

          // Mark onboarding as complete since user is returning
          ref.read(hasSeenIntroProvider.notifier).state = true;
          ref.read(hasCompletedProfileProvider.notifier).state = true;

          debugPrint('Returning user logged in: ${activeProfile.name}');
        } else {
          // Has profiles but no active one - go to profile selection
          debugPrint('User has profiles but no active profile - going to selection');
        }
      } else {
        // No profiles exist - check if we need to migrate from legacy system
        final playerProfileService = serviceManager.playerProfileService;
        final existingName = await playerProfileService.getPlayerName();

        if (existingName != 'Player' && existingName.isNotEmpty) {
          // Migrate existing profile data to multi-profile system
          final existingAvatar = await playerProfileService.getAvatar();
          final existingCountry = await playerProfileService.getCountry();
          final existingAgeGroup = await playerProfileService.getAgeGroup();

          final migratedProfile = await multiProfileService.createProfile(
            name: existingName,
            avatar: existingAvatar,
            country: existingCountry,
            ageGroup: existingAgeGroup,
          );

          if (migratedProfile != null) {
            await multiProfileService.setActiveProfile(migratedProfile.id);
            ref.read(activeProfileStateProvider.notifier).state = migratedProfile;

            // Mark onboarding as complete
            ref.read(hasSeenIntroProvider.notifier).state = true;
            ref.read(hasCompletedProfileProvider.notifier).state = true;

            debugPrint('Migrated existing profile: ${migratedProfile.name}');
          }
        } else {
          // No existing data - user will need to complete onboarding
          ref.read(hasSeenIntroProvider.notifier).state = false;
          ref.read(hasCompletedProfileProvider.notifier).state = false;

          debugPrint('New user - will need to complete onboarding');
        }
      }

      return null; // Success
    } catch (e) {
      return 'Login failed: ${e.toString()}';
    }
  }

  Future<String?> _signupUser(SignupData data, WidgetRef ref) async {
    try {
      await Future.delayed(loginTime);

      final email = data.name;
      final username = data.additionalSignupData?['Username'] ?? 'Player';
      final name = data.additionalSignupData?['Name'] ?? '';
      final phone = data.additionalSignupData?['phone_number'] ?? '';

      // Get services
      final authOps = ref.read(authOperationsProvider);
      final authService = ref.read(authServiceProvider);

      // Perform signup using auth operations
      await authOps.login(email!);

      // Save additional auth data
      if (phone.isNotEmpty) {
        await authService.secureStorage.setSecret('phone_number', phone);
      }
      if (email.isNotEmpty) {
        await authService.secureStorage.setUserEmail(email);
      }

      // Store signup data temporarily for profile creation
      ref.read(tempSignupDataProvider.notifier).state = {
        'username': username,
        'name': name,
        'email': email,
        'isPremium': data.additionalSignupData?['isPremiumUser'] == 'true',
      };

      // For new signups, they'll go through onboarding
      ref.read(hasSeenIntroProvider.notifier).state = false;
      ref.read(hasCompletedProfileProvider.notifier).state = false;

      debugPrint('New signup: $username - will complete onboarding');
      return null;
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

          // Navigation after successful auth - Fixed navigation issue
          onSubmitAnimationCompleted: () {
            // The router will handle navigation based on auth state and onboarding flags
            // We don't need to manually navigate here - just trigger a rebuild
            Future.microtask(() {
              // Force a router refresh to check the new auth state
              if (context.mounted) {
                context.go('/');
              }
            });
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

          // Footer text
          footer: 'New to Trivia Tycoon? Create an account to get started!',
        );
      },
    );
  }
}

// Provider for temporary signup data
final tempSignupDataProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

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
