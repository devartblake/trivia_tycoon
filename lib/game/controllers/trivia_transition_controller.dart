import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final triviaTransitionControllerProvider =
ChangeNotifierProvider((ref) => TriviaTransitionController(ref));

class TriviaTransitionController extends ChangeNotifier {
  final Ref ref;
  Timer? _timer;
  int _secondsRemaining = 5;

  int get secondsRemaining => _secondsRemaining;

  TriviaTransitionController(this.ref) {
    _startCountdown();
  }

  void _startCountdown() {
    _secondsRemaining = 5;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        notifyListeners();
        return;
      }
      _secondsRemaining--;
      notifyListeners();
    });
  }

  void navigateToNext(BuildContext context) {
    _timer?.cancel();
    context.go('/quiz');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
