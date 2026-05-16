import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trivia_tycoon/core/services/analytics/config_service.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/core/services/auth_error_messages.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/bootstrap/app_init.dart';
import '../core/constants/image_strings.dart';
import '../core/services/auth_token_store.dart';
import '../game/providers/auth_providers.dart';
import '../game/providers/core_providers.dart';
import '../game/providers/onboarding_providers.dart';
import '../game/providers/multi_profile_providers.dart';
import '../game/providers/web_link_providers.dart';
import 'onboarding/steps/constants.dart';
import 'web_link/qr_link_widget.dart';

// Platform check helper — avoids importing dart:io on web
bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// User data model for mock authentication
class MockUser {
  final String email;
  final String password;
  final String role; // 'player' or 'admin'
  final bool isPremium;

  const MockUser({
    required this.email,
    required this.password,
    required this.role,
    required this.isPremium,
  });

  bool get isAdmin => role == 'admin';
  bool get isPlayer => role == 'player';
}

/// Modern game-inspired login screen
class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/auth';
  const LoginScreen({super.key, this.startInSignUpMode = false});

  final bool startInSignUpMode;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const mockUsers = <String, MockUser>{
    'admin@gmail.com': MockUser(
      email: 'admin@gmail.com',
      password: 'admin123',
      role: 'admin',
      isPremium: true,
    ),
    'premium@gmail.com': MockUser(
      email: 'premium@gmail.com',
      password: 'premium',
      role: 'player',
      isPremium: true,
    ),
    'dribbble@gmail.com': MockUser(
      email: 'dribbble@gmail.com',
      password: '12345',
      role: 'player',
      isPremium: false,
    ),
    'hunter@gmail.com': MockUser(
      email: 'hunter@gmail.com',
      password: 'hunter',
      role: 'admin',
      isPremium: true,
    ),
    'near.huscarl@gmail.com': MockUser(
      email: 'near.huscarl@gmail.com',
      password: 'subscribe to pewdiepie',
      role: 'player',
      isPremium: false,
    ),
    '@.com': MockUser(
      email: '@.com',
      password: '.',
      role: 'player',
      isPremium: false,
    ),
  };

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSignUpMode = false;
  bool _isGameLoginLoading = false;
  bool _isGoogleWebLoading = false;
  bool _showWebLinking = false;
  bool _showQrCode = false;
  final TextEditingController _linkCodeController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Duration get loginTime => Duration(milliseconds: timeDilation.ceil() * 2250);

  @override
  void initState() {
    super.initState();
    _isSignUpMode = widget.startInSignUpMode;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Attempt silent game platform login (non-blocking).
    // If successful the user is navigated to home without needing to fill the form.
    if (ConfigService.useBackendAuth && (_isIOS || _isAndroid)) {
      _trySilentGameLogin();
    }
  }

  Future<void> _trySilentGameLogin() async {
    final authOps = ref.read(authOperationsProvider);
    final loggedIn = await authOps.trySilentGameLogin();
    if (loggedIn && mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _linkCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final authOps = ref.read(authOperationsProvider);
      final multiProfileService = ref.read(multiProfileServiceProvider);
      final serviceManager = ref.read(serviceManagerProvider);

      if (ConfigService.useBackendAuth) {
        // Backend authentication - authOps now uses LoginManager internally
        // LoginManager handles: tokens, device ID, profile updates
        if (_isSignUpMode) {
          await authOps.signup(email, password);
        } else {
          await authOps.loginWithPassword(email, password);
        }
      } else {
        // Legacy mock authentication (when backend is disabled)
        if (!mockUsers.containsKey(email)) {
          _showErrorSnackBar('User does not exist');
          setState(() => _isLoading = false);
          return;
        }

        final mockUser = mockUsers[email]!;
        if (mockUser.password != password) {
          _showErrorSnackBar('Incorrect password');
          setState(() => _isLoading = false);
          return;
        }

        // Use local auth for mock mode
        await authOps.login(email);
        final authService = ref.read(authServiceProvider);
        await authService.secureStorage.setSecret('user_role', mockUser.role);
        await authService.secureStorage
            .setSecret('is_premium', mockUser.isPremium.toString());
      }

      // Handle multi-profile migration/loading
      final existingProfiles = await multiProfileService.getAllProfiles();

      if (existingProfiles.isNotEmpty) {
        final activeProfile = await multiProfileService.getActiveProfile();

        if (activeProfile != null) {
          ref.read(activeProfileStateProvider.notifier).state = activeProfile;
          await ref.read(onboardingProgressProvider.notifier).updateProgress(
                hasSeenIntro: true,
                hasCompletedProfile: true,
              );
        }
      } else {
        // Migrate existing profile data if present
        final playerProfileService = serviceManager.playerProfileService;
        final existingName = await playerProfileService.getPlayerName();

        if (existingName != 'Player' && existingName.isNotEmpty) {
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
            ref.read(activeProfileStateProvider.notifier).state =
                migratedProfile;
            await ref.read(onboardingProgressProvider.notifier).updateProgress(
                  hasSeenIntro: true,
                  hasCompletedProfile: true,
                );
          }
        } else {
          // New user - needs onboarding
          await ref.read(onboardingProgressProvider.notifier).reset();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Complete onboarding to finish setting up your account.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      if (ConfigService.useBackendAuth) {
        await AppInit.initializeWebSocket();
      }

      setState(() => _isLoading = false);

      if (mounted) {
        final needsOnboarding = !(ref.read(hasCompletedProfileProvider));
        context.go(needsOnboarding ? '/profile-setup' : '/home');
      }
    } catch (e) {
      final baseMessage = ConfigService.useBackendAuth
          ? (_isSignUpMode
              ? AuthErrorMessages.getSignupErrorMessage(e)
              : AuthErrorMessages.getLoginErrorMessage(e))
          : 'Login failed: ${e.toString()}';

      // Append a platform-specific network hint for connection failures so
      // developers can diagnose URL / CORS issues without opening the logs.
      final errorStr = e.toString();
      final isNetworkError = errorStr.contains('SocketException') ||
          errorStr.contains('Connection refused') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('Network is unreachable') ||
          errorStr.contains('Connection timed out');

      String displayMessage = baseMessage;
      if (isNetworkError && ConfigService.useBackendAuth) {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          displayMessage =
              '$baseMessage\n\nTip: on an Android emulator the dev server must be '
              'reachable via 10.0.2.2, not localhost. Check API_BASE_URL in .env.';
        } else if (kIsWeb) {
          displayMessage =
              '$baseMessage\n\nTip: verify the backend is running and has CORS '
              'enabled for this origin (${Uri.base.origin}).';
        }
      }

      _showErrorSnackBar(displayMessage);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEnterKeySubmit([String? _]) async {
    if (_isLoading) return;
    await _handleLogin();
  }

  Future<void> _handleSocialLogin(String provider) async {
    if (!ConfigService.useBackendAuth) {
      _showErrorSnackBar('Enable backend auth to use social login.');
      return;
    }

    try {
      final authApiClient = ref.read(authApiClientProvider);
      final authUrl = await authApiClient.getOAuthUrl(provider);
      if (authUrl == null || authUrl.isEmpty) {
        _showErrorSnackBar('No auth URL returned for $provider.');
        return;
      }

      final uri = Uri.tryParse(authUrl);
      if (uri == null || !await canLaunchUrl(uri)) {
        _showErrorSnackBar('Unable to open $provider login.');
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar('Failed to start $provider login: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Web account linking handlers
  // -------------------------------------------------------------------------

  /// [Web only] Sign in with Google and obtain a backend session.
  Future<void> _handleGoogleWebSignIn() async {
    if (_isGoogleWebLoading || _isLoading) return;
    setState(() => _isGoogleWebLoading = true);

    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        setState(() => _isGoogleWebLoading = false);
        return;
      }

      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        _showErrorSnackBar('Google Sign-In failed: no ID token received.');
        setState(() => _isGoogleWebLoading = false);
        return;
      }

      final service = ref.read(webLinkServiceProvider);
      final result = await service.authenticateWithGoogleToken(idToken);

      // Save the returned session.
      final authTokenStore = ref.read(authTokenStoreProvider);
      await authTokenStore.save(AuthSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        userId: result.userId,
      ));

      ref.read(isLoggedInSyncProvider.notifier).state = true;
      if (mounted) context.go('/home');
    } catch (e) {
      _showErrorSnackBar('Google Sign-In failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGoogleWebLoading = false);
    }
  }

  /// [Web only] Enter a link code received from the mobile app.
  Future<void> _handleLinkCodeSubmit() async {
    final code = _linkCodeController.text.trim().toUpperCase();
    if (code.length < 6) {
      _showErrorSnackBar('Enter the 6-character code from the mobile app.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(webLinkServiceProvider);
      final result = await service.consumeLinkCode(code);

      final authTokenStore = ref.read(authTokenStoreProvider);
      await authTokenStore.save(AuthSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        userId: result.userId,
      ));

      ref.read(isLoggedInSyncProvider.notifier).state = true;
      if (mounted) context.go('/home');
    } catch (e) {
      _showErrorSnackBar('Invalid or expired code. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Called when the web QR scan succeeds and the backend returns a session token.
  void _handleQrSuccess(String sessionToken) async {
    // sessionToken is typically the full access token; the backend may also
    // establish a refresh token via a cookie. Adapt as needed.
    ref.read(isLoggedInSyncProvider.notifier).state = true;
    if (mounted) context.go('/home');
  }

  Future<void> _handleGamePlatformLogin() async {
    if (_isGameLoginLoading || _isLoading) return;

    setState(() => _isGameLoginLoading = true);

    try {
      final authOps = ref.read(authOperationsProvider);
      final gamePlatformService = ref.read(gamePlatformAuthServiceProvider);
      final identity = await gamePlatformService.signInSilently();

      if (identity == null) {
        _showErrorSnackBar(
          _isIOS
              ? 'Unable to connect to Game Center. Make sure you are signed in to Game Center in device Settings.'
              : 'Unable to connect to Google Play Games. Make sure the Play Games app is installed and signed in.',
        );
        setState(() => _isGameLoginLoading = false);
        return;
      }

      await authOps.loginWithGamePlatform(identity);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      final msg = AuthErrorMessages.getLoginErrorMessage(e);
      _showErrorSnackBar(msg);
    } finally {
      if (mounted) setState(() => _isGameLoginLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1F3A),
              Color(0xFF2D1B69),
              Color(0xFF1E1B4B),
            ],
          ),
        ),
        child: SafeArea(
          child: isDesktop || isTablet
              ? _buildDesktopLayout()
              : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Panel - Form
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937).withValues(alpha: 0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(10, 0),
                ),
              ],
            ),
            child: _buildLoginForm(),
          ),
        ),

        // Right Panel - Game Artwork
        Expanded(
          flex: 7,
          child: _buildGameArtwork(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: _buildLoginForm(),
      ),
    );
  }

  Widget _buildLoginForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Hero(
                    tag: Constants.logoTag,
                    child: Image.asset(
                      tSynaptixAppLogo,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Welcome Text
                  Hero(
                    tag: Constants.titleTag,
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        _isSignUpMode ? 'Create Account' : 'Welcome back',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUpMode
                        ? 'Sign up to start your trivia journey'
                        : 'Sign in to access your games and progress',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email address',
                          prefixIcon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: _handleEnterKeySubmit,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }

                            // Backend signup validation is stricter than login.
                            if (_isSignUpMode) {
                              if (value.length < 8) {
                                return 'Use at least 8 characters';
                              }
                              final hasLetter =
                                  RegExp(r'[A-Za-z]').hasMatch(value);
                              final hasNumber = RegExp(r'\d').hasMatch(value);
                              if (!hasLetter || !hasNumber) {
                                return 'Include at least one letter and one number';
                              }
                            } else if (value.length < 3) {
                              // Keep login lenient for existing legacy accounts.
                              return 'Password must be at least 3 characters';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Remember Me & Forgot Password
                        if (!_isSignUpMode)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(
                                            () => _rememberMe = value ?? false);
                                      },
                                      fillColor:
                                          WidgetStateProperty.resolveWith(
                                              (states) {
                                        if (states
                                            .contains(WidgetState.selected)) {
                                          return const Color(0xFF6366F1);
                                        }
                                        return Colors.transparent;
                                      }),
                                      side: BorderSide(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),

                        // Login Button
                        _buildPrimaryButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  _isSignUpMode ? 'Sign Up' : 'Log in',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Social Login Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.2),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.2),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Social Login Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              icon: FontAwesomeIcons.google,
                              onPressed: () => _handleSocialLogin('google'),
                            ),
                            const SizedBox(width: 16),
                            _buildSocialButton(
                              icon: FontAwesomeIcons.facebook,
                              onPressed: () => _handleSocialLogin('facebook'),
                            ),
                            const SizedBox(width: 16),
                            _buildSocialButton(
                              icon: FontAwesomeIcons.steam,
                              onPressed: () => _handleSocialLogin('steam'),
                            ),
                            const SizedBox(width: 16),
                            _buildSocialButton(
                              icon: FontAwesomeIcons.apple,
                              onPressed: () => _handleSocialLogin('apple'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Native game platform login (iOS: Game Center, Android: Play Games)
                        if ((_isIOS || _isAndroid) &&
                            ConfigService.useBackendAuth)
                          _buildNativeGameLoginButton(),
                        const SizedBox(height: 16),

                        // Web account linking (web platform only)
                        if (kIsWeb && ConfigService.useBackendAuth)
                          _buildWebLinkingSection(),
                        if (kIsWeb && ConfigService.useBackendAuth)
                          const SizedBox(height: 16),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUpMode
                                  ? 'Already have an account? '
                                  : 'Don\'t have account? ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _isSignUpMode = !_isSignUpMode);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _isSignUpMode ? 'Sign in' : 'Sign up',
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameArtwork() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.3),
            const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: CustomPaint(
              painter: GridPatternPainter(),
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game Character/Artwork Placeholder
                Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      tSynaptixAppLogo,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Game Title
                Text(
                  Constants.appName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Color(0xFF6366F1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Master every question, become the ultimate tycoon',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Info Badge
          Positioned(
            bottom: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                //backdropFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '10M+ Players Worldwide',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: Colors.white.withValues(alpha: 0.5),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: FaIcon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildWebLinkingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or link mobile account',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Expand/collapse toggle
        TextButton(
          onPressed: () => setState(() => _showWebLinking = !_showWebLinking),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showWebLinking ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF6366F1),
                size: 18,
              ),
              const SizedBox(width: 4),
              const Text(
                'Link from Mobile App',
                style: TextStyle(color: Color(0xFF6366F1), fontSize: 13),
              ),
            ],
          ),
        ),

        if (_showWebLinking) ...[
          const SizedBox(height: 16),

          // Method 1: Google Sign-In on web
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isGoogleWebLoading ? null : _handleGoogleWebSignIn,
              icon: _isGoogleWebLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.g_mobiledata_rounded, size: 20),
              label: const Text('Continue with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Method 2: One-time link code input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _linkCodeController,
                  decoration: InputDecoration(
                    hintText: 'Enter 6-char code from app',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 4,
                    fontFamily: 'monospace',
                  ),
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      null,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLinkCodeSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Link'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Method 3: QR code
          TextButton(
            onPressed: () => setState(() => _showQrCode = !_showQrCode),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_rounded,
                    size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Text(
                  _showQrCode ? 'Hide QR Code' : 'Show QR Code to Scan',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_showQrCode) ...[
            const SizedBox(height: 12),
            QrLinkWidget(onSuccess: _handleQrSuccess),
          ],
        ],
      ],
    );
  }

  Widget _buildNativeGameLoginButton() {
    final isIOS = _isIOS;
    final label =
        isIOS ? 'Continue with Game Center' : 'Continue with Play Games';
    final icon = isIOS ? FontAwesomeIcons.gamepad : FontAwesomeIcons.google;

    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: (_isGameLoginLoading || _isLoading)
            ? null
            : _handleGamePlatformLogin,
        icon: _isGameLoginLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              )
            : FaIcon(icon, size: 18, color: const Color(0xFF6366F1)),
        label: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6366F1),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

// Grid Pattern Painter for Background
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Provider for temporary signup data
final tempSignupDataProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);
