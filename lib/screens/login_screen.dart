import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../ui_components/login/trivia_login.dart';
import '../core/constants/image_strings.dart';
import 'onboarding/widget/constants.dart';

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

    final role = 'player';

    final authService = ref.read(authServiceProvider);
    final profileService = ref.read(playerProfileServiceProvider);
    final secureStorage = ref.read(secureStorageProvider);

    // App login logic
    await authService.login(data.name);
    await secureStorage.setLoggedIn(true);
    await profileService.saveUserRoles([role]); // or 'user'

    return null; // Success triggers `onSubmitAnimationCompleted`
  }

  Future<String?> _signupUser(SignupData data, WidgetRef ref) async {
    final playerProfileService = ref.read(playerProfileServiceProvider);
    final authService = ref.read(authServiceProvider);
    final onboardingService = ref.read(onboardingSettingsServiceProvider);

    try {
      // Simulate server-side processing delay
      await Future.delayed(loginTime);

      // Extract from signup form
      final email = data.name;
      final username = data.additionalSignupData?['Username'] ?? 'Player';
      final name = data.additionalSignupData?['Name'] ?? '';
      final phone = data.additionalSignupData?['phone_number'] ?? '';

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

      // Save login + onboarding flag
      await authService.setLoggedIn(true);
      await authService.secureStorage.setUserEmail(email!);
      await onboardingService.setHasCompletedOnboarding(false);

      return null; // Success
    } catch (e) {
      return '❌ Signup failed: ${e.toString()}';
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
      userHint: 'User',
      passwordHint: 'Pass',
      confirmPasswordHint: 'Confirm',
      loginButton: 'LOG IN',
      signupButton: 'REGISTER',
      forgotPasswordButton: 'Forgot huh?',
      recoverPasswordButton: 'HELP ME',
      goBackButton: 'GO BACK',
      confirmPasswordError: 'Not match!',
      recoverPasswordIntro: 'Don\'t feel bad. Happens all the time.',
      recoverPasswordDescription: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
      recoverPasswordSuccess: 'Password rescued successfully',
      tycoonToastTitleError: 'Oh no!',
      tycoonToastTitleSuccess: 'Success!',
      providersTitleFirst: 'login with',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingService = ref.read(onboardingSettingsServiceProvider);

    return FutureBuilder<LoginMessages>(
      future: getLoginMessages(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
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
          loginProviders: [
            LoginProvider(
              button: Buttons.linkedIn,
              label: 'Sign in with LinkedIn',
              callback: () async {
                return null;
              },
              providerNeedsSignUpCallback: () {
                // put here your logic to conditionally show the additional fields
                return Future.value(true);
              },
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
                debugPrint('start github sign in');
                await Future.delayed(loginTime);
                debugPrint('stop github sign in');
                return null;
              },
            ),
          ],
          theme: LoginTheme(
            primaryColor: Colors.blue,
            accentColor: Colors.blueAccent,
            errorColor: Colors.deepOrange,
            pageColorLight: Colors.indigo.shade300,
            pageColorDark: Colors.indigo.shade500,
            logoWidth: 0.80,
            titleStyle: TextStyle(
              color: Colors.greenAccent,
              fontFamily: 'Quicksand',
              letterSpacing: 4,
            ),
            // beforeHeroFontSize: 50,
            // afterHeroFontSize: 20,
            bodyStyle: TextStyle(
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.underline,
            ),
            textFieldStyle: TextStyle(
              color: Colors.orange,
              shadows: [Shadow(color: Colors.yellow, blurRadius: 2)],
            ),
            buttonStyle: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.yellow,
            ),
            cardTheme: CardTheme(
              color: Colors.yellow.shade100,
              elevation: 5,
              margin: EdgeInsets.only(top: 15),
              shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0)),
            ),
            buttonTheme: LoginButtonTheme(
              splashColor: Colors.purple,
              backgroundColor: Colors.pinkAccent,
              highlightColor: Colors.lightGreen,
              elevation: 9.0,
              highlightElevation: 6.0,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              // shape: CircleBorder(side: BorderSide(color: Colors.green)),
              // shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(55.0)),
            ),
          ),
          userValidator: (value) {
            if (!value!.contains('@') || !value.endsWith('.com')) {
              return "Email must contain '@' and end with '.com'";
            }
            return null;
          },
          passwordValidator: (value) {
            if (value!.isEmpty) return 'Password is empty';
            return null;
          },
          onLogin: (data) => _loginUser(data, ref),
          onSignup: (data) => _signupUser(data, ref),
          onRecoverPassword: _recoverPassword,
          onSubmitAnimationCompleted: () async {
            final hasOnboarded = await onboardingService
                .hasCompletedOnboarding();
            if (context.mounted) {
              context.go(hasOnboarded ? '/' : '/onboarding');
            }
          },
          additionalSignupFields: const [
            UserFormField(keyName: 'Username', icon: Icon(FontAwesomeIcons.userLarge)),
            UserFormField(keyName: 'Name'),
            UserFormField(keyName: 'Surname'),
            UserFormField(keyName: 'phone_number',
              displayName: 'Phone Number',
              userType: LoginUserType.phone,
            ),
          ],
          headerWidget: const IntroWidget(),
        );
      }
    );
  }
}

class IntroWidget extends StatelessWidget {
  const IntroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "You are trying to login/sign up on server hosted on "),
              TextSpan(text: "example.com", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          textAlign: TextAlign.justify,
        ),
        Row(
          children: <Widget>[
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.all(8.0), child: Text("Authenticate")),
            Expanded(child: Divider()),
          ],
        ),
      ],
    );
  }
}
