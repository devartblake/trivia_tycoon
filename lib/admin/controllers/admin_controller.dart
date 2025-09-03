import 'package:flutter/material.dart';

class AdminController extends ChangeNotifier {
  int _selectedTab = 0;

  int get selectedTab => _selectedTab;

  void selectTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  void refreshDashboard() {
    // Refresh data across the admin screens if needed
    notifyListeners();
  }
}
