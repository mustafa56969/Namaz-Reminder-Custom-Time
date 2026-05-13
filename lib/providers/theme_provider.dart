import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  int _primaryHue = 210; // Default blue hue (Fajr)

  ThemeMode get mode => _mode;
  int get primaryHue => _primaryHue;

  Color get seedColor => HSLColor.fromAHSL(1, _primaryHue.toDouble(), 0.7, 0.5).toColor();

  void toggleTheme() {
    if (_mode == ThemeMode.system) {
      _mode = ThemeMode.light;
    } else if (_mode == ThemeMode.light) {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  void setPrimaryHue(int hue) {
    if (_primaryHue != hue) {
      _primaryHue = hue;
      notifyListeners();
    }
  }
}
