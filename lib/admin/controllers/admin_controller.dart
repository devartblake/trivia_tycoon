import 'package:flutter/material.dart';

/// Controller for managing admin dashboard state and navigation
class AdminController extends ChangeNotifier {
  int _selectedTab = 0;
  bool _isRefreshing = false;

  int get selectedTab => _selectedTab;
  bool get isRefreshing => _isRefreshing;

  /// Select a tab and notify listeners
  void selectTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    // Simulate refresh delay - replace with actual data fetching
    await Future.delayed(const Duration(milliseconds: 500));

    _isRefreshing = false;
    notifyListeners();
  }

  /// Reset to default state
  void reset() {
    _selectedTab = 0;
    _isRefreshing = false;
    notifyListeners();
  }
}
