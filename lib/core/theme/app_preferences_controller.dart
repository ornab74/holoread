import 'package:flutter/foundation.dart';

class AppPreferencesController extends ChangeNotifier {
  bool _lowPowerMode = false;
  bool _reducedMotion = false;
  bool _oledMode = false;

  bool get lowPowerMode => _lowPowerMode;
  bool get reducedMotion => _reducedMotion;
  bool get oledMode => _oledMode;

  void setLowPowerMode(bool value) {
    if (_lowPowerMode == value) return;
    _lowPowerMode = value;
    notifyListeners();
  }

  void setReducedMotion(bool value) {
    if (_reducedMotion == value) return;
    _reducedMotion = value;
    notifyListeners();
  }

  void setOledMode(bool value) {
    if (_oledMode == value) return;
    _oledMode = value;
    notifyListeners();
  }
}
