import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:synaptix/core/manager/log_manager.dart';
import 'package:synaptix/core/manager/service_manager.dart';
import 'package:synaptix/core/navigation/canonical_routes.dart';
import 'package:synaptix/core/services/guest_api_gate.dart';
import 'package:synaptix/core/services/guest_data_wiper.dart';
import 'package:synaptix/core/services/guest_session_store.dart';
import 'package:synaptix/ui_components/synaptix_toast/synaptix_toast_helper.dart';
import 'package:synaptix/ui_components/synaptix_toast/synaptix_toast_service.dart';

/// Guest session lifecycle:
/// - gate API (via [GuestApiGate])
/// - toast after [sessionWarnAfter] of continuous guest play
/// - toast when the user begins leaving the site/app
/// - wipe **play** data (not onboarding) after [wipeAfterLeave] away
///
/// Defaults: warn at 20 minutes, wipe play data after 15 minutes away.
class GuestSessionController with WidgetsBindingObserver {
  GuestSessionController({
    required ServiceManager serviceManager,
    this.sessionWarnAfter = const Duration(minutes: 20),
    this.wipeAfterLeave = const Duration(minutes: 15),
    this.tickInterval = const Duration(seconds: 30),
    GuestDataWiper? wiper,
    Future<void> Function(String route)? navigateTo,
    void Function(bool isGuest)? onGuestFlagChanged,
  })  : _wiper = wiper ?? GuestDataWiper(serviceManager),
        _navigateTo = navigateTo,
        _onGuestFlagChanged = onGuestFlagChanged;

  final GuestDataWiper _wiper;
  final Duration sessionWarnAfter;
  final Duration wipeAfterLeave;
  final Duration tickInterval;
  final Future<void> Function(String route)? _navigateTo;
  final void Function(bool isGuest)? _onGuestFlagChanged;

  Timer? _tickTimer;
  bool _started = false;
  bool _leaveToastShown = false;
  bool _wipeInProgress = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    await GuestSessionStore.hydrate();
    _onGuestFlagChanged?.call(GuestApiGate.isGuestSession);
    WidgetsBinding.instance.addObserver(this);

    // Cold start: guest left previously and is past the wipe window.
    await _maybeWipeAfterLeave(reason: 'cold_start');

    if (GuestApiGate.isGuestSession) {
      final started = await GuestSessionStore.sessionStartedAt();
      if (started == null) {
        await GuestSessionStore.startGuestSession();
      }
      _onGuestFlagChanged?.call(true);
      _startTicker();
      LogManager.debug('[GuestSessionController] Tracking guest session');
    }
  }

  Future<void> onGuestModeEntered() async {
    await GuestSessionStore.startGuestSession();
    _onGuestFlagChanged?.call(true);
    _leaveToastShown = false;
    _startTicker();
  }

  Future<void> onAuthenticated() async {
    await GuestSessionStore.clearGuestSession();
    _onGuestFlagChanged?.call(false);
    _stopTicker();
    _leaveToastShown = false;
  }

  void dispose() {
    _stopTicker();
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!GuestApiGate.isGuestSession) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        unawaited(_handleLeaving());
        break;
      case AppLifecycleState.resumed:
        unawaited(_handleReturned());
        break;
      case AppLifecycleState.detached:
        unawaited(GuestSessionStore.markLeft());
        break;
    }
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(tickInterval, (_) {
      unawaited(_onTick());
    });
    // Immediate check (covers long-running sessions after reload).
    unawaited(_onTick());
  }

  void _stopTicker() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  Future<void> _onTick() async {
    if (!GuestApiGate.isGuestSession) return;

    final started = await GuestSessionStore.sessionStartedAt();
    if (started == null) return;

    final elapsed = DateTime.now().toUtc().difference(started);
    if (elapsed < sessionWarnAfter) return;

    final alreadyWarned = await GuestSessionStore.hasWarned25m();
    if (alreadyWarned) return;

    await GuestSessionStore.markWarned25m();
    final warnMinutes = sessionWarnAfter.inMinutes;
    await _showSignupToast(
      title: 'Guest session running long',
      message:
          'You have been playing as a guest for $warnMinutes+ minutes. Create a free account to keep play progress and unlock online features. Your onboarding setup is already saved.',
    );
  }

  Future<void> _handleLeaving() async {
    if (!GuestApiGate.isGuestSession) return;

    await GuestSessionStore.markLeft();

    if (_leaveToastShown) return;
    _leaveToastShown = true;

    final wipeMinutes = wipeAfterLeave.inMinutes;
    await _showSignupToast(
      title: 'Leaving as a guest?',
      message:
          'Play progress is temporary. If you stay away for $wipeMinutes minutes, coins, caches, and this guest play session will be cleared (onboarding stays). Sign up to keep everything.',
      duration: const Duration(seconds: 6),
    );
  }

  Future<void> _handleReturned() async {
    _leaveToastShown = false;
    final wiped = await _maybeWipeAfterLeave(reason: 'resume');
    if (wiped) return;
    await GuestSessionStore.clearLeft();
  }

  /// Returns true if a wipe was performed.
  Future<bool> _maybeWipeAfterLeave({required String reason}) async {
    if (_wipeInProgress) return false;

    final isGuest = await GuestSessionStore.isGuestSessionActive();
    if (!isGuest && !GuestApiGate.isGuestSession) return false;

    final left = await GuestSessionStore.leftAt();
    if (left == null) return false;

    final away = DateTime.now().toUtc().difference(left);
    if (away < wipeAfterLeave) return false;

    _wipeInProgress = true;
    try {
      LogManager.info(
        '[GuestSessionController] Guest left for ${away.inMinutes}m ($reason) — wiping',
        source: 'GuestSessionController',
      );
      await _wiper.wipeAllGuestData();
      _onGuestFlagChanged?.call(false);
      _stopTicker();

      final wipeMinutes = wipeAfterLeave.inMinutes;
      await SynaptixToastService.info(
        title: 'Guest play session ended',
        message:
            'Your guest play data was cleared after $wipeMinutes minutes away. Onboarding is still saved — sign up to keep progress permanently.',
        duration: const Duration(seconds: 5),
      );

      await _goToRegisterOrLogin();
      return true;
    } catch (e, st) {
      LogManager.error(
        'Guest wipe failed',
        source: 'GuestSessionController',
        error: e,
        stackTrace: st,
      );
      return false;
    } finally {
      _wipeInProgress = false;
    }
  }

  Future<void> _showSignupToast({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 5),
  }) async {
    final button = TextButton(
      onPressed: () {
        unawaited(_goToRegisterOrLogin());
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
        ),
      ),
      child: const Text(
        'Sign up free',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );

    await SynaptixToastService.show(
      SynaptixToastHelper.createAction(
        title: title,
        message: message,
        button: button,
        duration: duration,
      ),
    );
  }

  Future<void> _goToRegisterOrLogin() async {
    final custom = _navigateTo;
    if (custom != null) {
      await custom(canonicalRegisterRoute);
      return;
    }

    // Prefer go_router via navigator key when available.
    final navContext = SynaptixToastService.navigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      try {
        GoRouter.of(navContext).go(canonicalRegisterRoute);
        return;
      } catch (_) {
        // fall through
      }
    }

    // Last resort: schedule after frame when router may not be ready yet.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ctx = SynaptixToastService.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        try {
          GoRouter.of(ctx).go(canonicalRegisterRoute);
        } catch (e) {
          LogManager.debug(
              '[GuestSessionController] navigate to register failed: $e');
        }
      }
    });
  }
}
