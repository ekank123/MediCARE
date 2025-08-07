import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationProvider extends ChangeNotifier {
  final String key = 'language';
  late SharedPreferences _prefs;
  late Locale _locale;

  Locale get locale => _locale;

  // Available languages
  final List<Locale> supportedLocales = [
    const Locale('en', 'US'), // English
    const Locale('hi', 'IN'), // Hindi
    const Locale('bn', 'IN'), // Bengali
    const Locale('te', 'IN'), // Telugu
    const Locale('ta', 'IN'), // Tamil
    const Locale('mr', 'IN'), // Marathi
    const Locale('gu', 'IN'), // Gujarati
    const Locale('kn', 'IN'), // Kannada
    const Locale('ml', 'IN'), // Malayalam
    const Locale('pa', 'IN'), // Punjabi
  ];

  // Language names for display
  Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिंदी', // Hindi
    'bn': 'বাংলা', // Bengali
    'te': 'తెలుగు', // Telugu
    'ta': 'தமிழ்', // Tamil
    'mr': 'मराठी', // Marathi
    'gu': 'ગુજરાતી', // Gujarati
    'kn': 'ಕನ್ನಡ', // Kannada
    'ml': 'മലയാളം', // Malayalam
    'pa': 'ਪੰਜਾਬੀ', // Punjabi
  };

  LocalizationProvider() {
    _locale = const Locale('en', 'US');
    _loadFromPrefs();
  }

  // Initialize preferences
  _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Load language preference from SharedPreferences
  _loadFromPrefs() async {
    await _initPrefs();
    String languageCode = _prefs.getString(key) ?? 'en';
    String countryCode = 'US';
    
    if (languageCode != 'en') {
      countryCode = 'IN';
    }
    
    _locale = Locale(languageCode, countryCode);
    notifyListeners();
  }

  // Save language preference to SharedPreferences
  _saveToPrefs() async {
    await _initPrefs();
    _prefs.setString(key, _locale.languageCode);
  }

  // Change language
  void setLocale(Locale locale) {
    if (!supportedLocales.contains(locale)) return;
    
    _locale = locale;
    _saveToPrefs();
    notifyListeners();
  }

  // Get language name for display
  String getDisplayLanguage(Locale locale) {
    return languageNames[locale.languageCode] ?? 'Unknown';
  }

  // Get current language name
  String get currentLanguageName {
    return getDisplayLanguage(_locale);
  }
  
  // Get list of supported language codes
  List<String> get supportedLanguages {
    return languageNames.keys.toList();
  }
  
  // Get language name from language code
  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? 'Unknown';
  }
}