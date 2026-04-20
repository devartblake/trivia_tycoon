import 'package:flutter/material.dart';
import '../../../game/services/flow_connect_level_generator.dart';

class FlowConnectSettings extends ChangeNotifier {
  int _gridSize = 5;
  FlowConnectDifficulty _difficulty = FlowConnectDifficulty.medium;

  int get gridSize => _gridSize;
  FlowConnectDifficulty get difficulty => _difficulty;

  void setGridSize(int size) {
    if (_gridSize != size) {
      _gridSize = size;
      notifyListeners();
    }
  }

  void setDifficulty(FlowConnectDifficulty difficulty) {
    if (_difficulty != difficulty) {
      _difficulty = difficulty;
      notifyListeners();
    }
  }
}
