import 'package:flutter/material.dart';

class ThemeModeController extends ChangeNotifier {
  ThemeModeController._();

  static final ThemeModeController instance = ThemeModeController._();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void update(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
  }
}
