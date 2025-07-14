import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  // Helper method to get the current theme
  ThemeData get themeData => _isDarkMode 
      ? ThemeData.dark().copyWith(
          primaryColor: Colors.blueGrey[800],
          colorScheme: ColorScheme.dark(
            primary: Colors.blueGrey[500]!,
            secondary: Colors.blueGrey[300]!,
            surface: Colors.blueGrey[900]!,
            background: Colors.blueGrey[900]!,
          ),
          scaffoldBackgroundColor: Colors.blueGrey[900],
          cardColor: Colors.blueGrey[800],
          dividerColor: Colors.blueGrey[700],
          dialogBackgroundColor: Colors.blueGrey[800],
        )
      : ThemeData.light().copyWith(
          primaryColor: Colors.blue[700],
          colorScheme: ColorScheme.light(
            primary: Colors.blue[700]!,
            secondary: Colors.blue[500]!,
          ),
          scaffoldBackgroundColor: Colors.grey[100],
          cardColor: Colors.white,
        );
}
