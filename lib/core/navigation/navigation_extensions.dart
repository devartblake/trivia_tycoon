import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Safe navigation helpers that work on mobile, web, and desktop.
///
/// On web a screen can be the first entry in the browser history (accessed
/// via direct URL), leaving the GoRouter stack empty.  Calling context.pop()
/// on an empty stack throws "There is nothing to pop".  Use these helpers
/// instead of bare context.pop() for all back-navigation.
extension SafeGoNavigation on BuildContext {
  /// Navigate back if possible, otherwise go to [fallback].
  ///
  /// Use this instead of context.pop() for every back button / close action
  /// on a full screen (not inside showDialog – those are always safe).
  void safeBack({String fallback = '/home'}) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }

  /// Same as [safeBack] but passes a [result] to the waiting push() caller.
  ///
  /// Falls back to [fallback] when there is nothing to pop (e.g. direct URL).
  void safeBackWithResult<T>(T result, {String fallback = '/home'}) {
    if (canPop()) {
      pop(result);
    } else {
      go(fallback);
    }
  }
}
