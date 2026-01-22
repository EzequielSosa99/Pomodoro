import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Localization service for i18n
class LocalizationService extends ChangeNotifier {
  Locale _locale;
  Map<String, dynamic> _localizedStrings = {};

  LocalizationService([String languageCode = 'en'])
      : _locale = Locale(languageCode) {
    _loadLanguage(languageCode);
  }

  Locale get locale => _locale;

  // Load language JSON file
  Future<void> _loadLanguage(String languageCode) async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/l10n/$languageCode.json');
      _localizedStrings = jsonDecode(jsonString);
    } catch (e) {
      // Fallback to English if language not found
      final jsonString = await rootBundle.loadString('assets/l10n/en.json');
      _localizedStrings = jsonDecode(jsonString);
    }
  }

  // Change language
  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    await _loadLanguage(languageCode);
    notifyListeners();
  }

  // Translate key with dot notation (e.g., "home.title")
  String translate(String key, {Map<String, dynamic>? params}) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;

    // Navigate through nested keys
    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        // Key not found, return the key itself as fallback
        return key;
      }
    }

    String result = value.toString();

    // Replace parameters if provided (e.g., {current}, {total})
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        result = result.replaceAll('{$paramKey}', paramValue.toString());
      });
    }

    return result;
  }

  // Shorthand method
  String t(String key, {Map<String, dynamic>? params}) =>
      translate(key, params: params);
}
