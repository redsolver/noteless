import 'package:flutter/material.dart';
import 'package:preferences/preference_service.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeNotifier() {
    setTheme(PrefService.getString('theme') ?? 'light');
  }
  static final List<ThemeData> themeData = [
    ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xfff5b746),
        accentColor: Color(0xfff5b746)),
    ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xfff5b746),
        accentColor: Color(0xfff5b746))
  ];

  ThemeType _currentTheme = ThemeType.light;
  ThemeData _currentThemeData = themeData[0];

  void switchTheme() => currentTheme == ThemeType.light
      ? currentTheme = ThemeType.dark
      : currentTheme = ThemeType.light;

  set currentTheme(ThemeType theme) {
    if (theme != null) {
      _currentTheme = theme;
      _currentThemeData =
          currentTheme == ThemeType.light ? themeData[0] : themeData[1];

      notifyListeners();
    }
  }

  setTheme(String theme) {
    switch (theme) {
      case 'light':
        currentTheme = ThemeType.light;
        break;
      case 'dark':
        currentTheme = ThemeType.dark;
        break;
    }
    _currentThemeData =
        currentTheme == ThemeType.light ? themeData[0] : themeData[1];
    notifyListeners();
  }

  get currentTheme => _currentTheme;
  get currentThemeData => _currentThemeData;
}

enum ThemeType { light, dark }
