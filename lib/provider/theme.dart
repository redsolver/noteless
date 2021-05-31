import 'package:flutter/material.dart';
import 'package:preferences/preference_service.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeNotifier() {
    _accentColor = Color(PrefService.getInt('theme_color') ?? 0xff21d885);
    updateTheme(PrefService.getString('theme') ?? 'light');
  }

  ThemeType currentTheme = ThemeType.light;
  ThemeData _currentThemeData;

/*  void switchTheme() => currentTheme == ThemeType.light
      ? currentTheme = ThemeType.dark
      : currentTheme = ThemeType.light; */

  updateTheme([String theme]) {
    switch (theme) {
      case 'light':
        currentTheme = ThemeType.light;
        break;
      case 'dark':
        currentTheme = ThemeType.dark;
        break;
      case 'black':
        currentTheme = ThemeType.dark;
        break;
    }
    _currentThemeData = ThemeData(
      brightness:
          currentTheme == ThemeType.light ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: theme == 'black' ? Colors.black : null,
      backgroundColor: theme == 'black' ? Colors.black : null,
      dialogBackgroundColor: theme == 'black' ? Colors.black : null,
      canvasColor: theme == 'black' ? Colors.black : null,
      cardColor: theme == 'black' ? Colors.black : null,
      accentColor: _accentColor,
      primaryColor: _accentColor,
      toggleableActiveColor: _accentColor,
      highlightColor: _accentColor,
      buttonColor: _accentColor,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accentColor,
      ),
      buttonTheme: ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
        buttonColor: _accentColor,
      ),
      textTheme: TextTheme(
        button: TextStyle(color: _accentColor),
      ),
    );
    notifyListeners();
  }

  ThemeData get currentThemeData => _currentThemeData;

  Color _accentColor;

  get accentColor => _accentColor;
  set accentColor(Color color) {
    if (color != null) {
      _accentColor = color;

      updateTheme();
    }
  }
}

enum ThemeType { light, dark }
