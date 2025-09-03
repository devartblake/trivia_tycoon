import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';
import '../trivia_login.dart';

enum AuthMode { signup, login }
enum AuthType { provider, userPassword }

/// A callback for provider login actions.
/// Should return `null` on success or a `String` error message on failure.
typedef ProviderAuthCallback = Future<String?> Function();

/// Optional callback to determine if additional signup fields are required.
/// Should return `true` if extra signup fields should be shown.
typedef ProviderNeedsSignUpCallback = Future<bool> Function();

final authProvider = ChangeNotifierProvider<Auth>((ref) => Auth());

class Auth extends ChangeNotifier {
  Auth({
    this.loginProviders = const [],
    this.onLogin,
    this.onSignup,
    this.onRecoverPassword,
    this.onConfirmRecover,
    this.onConfirmSignup,
    this.confirmSignupRequired,
    this.onResendCode,
    this.beforeAdditionalFieldsCallback,
    String email = '',
    String password = '',
    String confirmPassword = '',
    AuthMode initialAuthMode = AuthMode.login,
    this.termsOfService = const [],
  })  : _email = email,
        _password = password,
        _confirmPassword = confirmPassword,
        _mode = initialAuthMode;

  final LoginCallback? onLogin;
  final SignupCallback? onSignup;
  final RecoverCallback? onRecoverPassword;
  final List<LoginProvider> loginProviders;
  final ConfirmRecoverCallback? onConfirmRecover;
  final ConfirmSignupCallback? onConfirmSignup;
  final ConfirmSignupRequiredCallback? confirmSignupRequired;
  final SignupCallback? onResendCode;
  final List<TermOfService> termsOfService;
  final BeforeAdditionalFieldsCallback? beforeAdditionalFieldsCallback;

  AuthType _authType = AuthType.userPassword;
  AuthType get authType => _authType;
  set authType(AuthType authType) {
    _authType = authType;
    notifyListeners();
  }

  AuthMode _mode = AuthMode.login;
  AuthMode get mode => _mode;
  set mode(AuthMode value) {
    _mode = value;
    notifyListeners();
  }

  bool get isLogin => _mode == AuthMode.login;
  bool get isSignup => _mode == AuthMode.signup;
  int currentCardIndex = 0;

  AuthMode opposite() => _mode == AuthMode.login ? AuthMode.signup : AuthMode.login;

  AuthMode switchAuth() {
    mode = opposite();
    return mode;
  }

  String _email = '';
  String get email => _email;
  set email(String email) {
    _email = email;
    notifyListeners();
  }

  String _password = '';
  String get password => _password;
  set password(String password) {
    _password = password;
    notifyListeners();
  }

  String _confirmPassword = '';
  String get confirmPassword => _confirmPassword;
  set confirmPassword(String confirmPassword) {
    _confirmPassword = confirmPassword;
    notifyListeners();
  }

  Map<String, String>? _additionalSignupData;
  Map<String, String>? get additionalSignupData => _additionalSignupData;
  set additionalSignupData(Map<String, String>? value) {
    _additionalSignupData = value;
    notifyListeners();
  }

  List<TermOfServiceResult> getTermsOfServiceResults() {
    return termsOfService.map((e) => TermOfServiceResult(term: e, accepted: e.checked)).toList();
  }
}

class AuthService {
  final SecureStorage secureStorage;
  final GeneralKeyValueStorageService generalKey;
  final PlayerProfileService playerProfileService;

  AuthService({
    required this.secureStorage,
    required this.generalKey,
    required this.playerProfileService,
  });

  static const String _loggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'user_email';

  /// ✅ Checks login status from key-value storage
  Future<bool> isLoggedIn() async {
    final value = await generalKey.getBool(_loggedInKey);
    return value is bool ? value : false;
  }

  /// ✅ Persists login state
  Future<void> setLoggedIn(bool value) async {
    await generalKey.setBool(_loggedInKey, value);
  }

  /// ✅ Login user and persist credentials
  Future<void> login(String email, {String userId = 'guest', bool isPremiumUser = false, List<String> roles = const ['player']}) async {
    // Save login flag to local storage
    await generalKey.setBool(_loggedInKey, true);
    await secureStorage.setSecret(_userEmailKey, email);

    // 🌟 Persist profile details
    await playerProfileService.savePlayerName(email.split('@').first);
    await playerProfileService.saveUserRole(roles.first); // Simplified
    await playerProfileService.setPremiumStatus(isPremiumUser);
  }

  /// ✅ Logout user and clear session state
  Future<void> logout(BuildContext context) async {
    await generalKey.setBool(_loggedInKey, false);
    await secureStorage.removeSecret(_userEmailKey);


    // 🔒 Cleanup logic
    await playerProfileService.clearProfile();

    // 🔒 Add any cleanup logic for session, analytics, cache, etc. here

    if (!context.mounted) return;
    context.go('/login'); // Navigate back to login
  }

  /// ✅ Optional getter for stored email
  Future<String?> getStoredEmail() async {
    return await secureStorage.getSecret(_userEmailKey);
  }
}

// Callback typedefs

typedef LoginCallback = Future<String?>? Function(LoginData);
typedef SignupCallback = Future<String?>? Function(SignupData);
typedef RecoverCallback = Future<String?>? Function(String);
typedef ConfirmRecoverCallback = Future<String?>? Function(String, LoginData);
typedef ConfirmSignupCallback = Future<String?>? Function(String, LoginData);
typedef ConfirmSignupRequiredCallback = Future<bool> Function(LoginData);
typedef BeforeAdditionalFieldsCallback = Future<String?>? Function(SignupData);
