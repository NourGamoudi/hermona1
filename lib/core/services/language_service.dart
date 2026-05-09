import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LanguageService {
  static const String _langKey = 'selected_language';
  static bool? _isLanguageSetCache;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLanguageSetCache = prefs.containsKey(_langKey);
  }

  static bool get isLanguageSetSync => _isLanguageSetCache ?? false;

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, languageCode);
    _isLanguageSetCache = true;
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'fr';
  }

  Future<bool> isLanguageSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_langKey);
  }

  Future<Locale> getLocale() async {
    final code = await getLanguage();
    return Locale(code);
  }
}
