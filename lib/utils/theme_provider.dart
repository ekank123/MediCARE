import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final String key = 'theme';
  late SharedPreferences _prefs;
  late bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _isDarkMode = false;
    _loadFromPrefs();
  }

  // Initialize preferences
  _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Load theme preference from SharedPreferences
  _loadFromPrefs() async {
    await _initPrefs();
    _isDarkMode = _prefs.getBool(key) ?? false;
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  _saveToPrefs() async {
    await _initPrefs();
    _prefs.setBool(key, _isDarkMode);
  }

  // Toggle theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }

  // Get theme data
  ThemeData getTheme() {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  // Light theme
  final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF4CAF50), // Green
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF4CAF50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF4CAF50),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[100],
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.black87),
      displayMedium: TextStyle(color: Colors.black87),
      displaySmall: TextStyle(color: Colors.black87),
      headlineMedium: TextStyle(color: Colors.black87),
      headlineSmall: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black87),
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );

  // Dark theme
  final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF81C784), // Light Green
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF81C784),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2C2C2C),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF81C784),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF81C784),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF81C784), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white),
      displayMedium: TextStyle(color: Colors.white),
      displaySmall: TextStyle(color: Colors.white),
      headlineMedium: TextStyle(color: Colors.white),
      headlineSmall: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
    ),
  );
}