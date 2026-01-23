import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pomodoro_config.dart';
import '../models/pomodoro_state.dart';
import '../models/task.dart';

// Storage service for local persistence
class StorageService extends ChangeNotifier {
  static const String _configKey = 'pomodoro_config';
  static const String _stateKey = 'pomodoro_state';
  static const String _tasksKey = 'tasks_';
  static const String _languageKey = 'language';
  static const String _soundKey = 'sound_enabled';
  static const String _vibrationKey = 'vibration_enabled';
  static const String _themeKey = 'theme_mode';
  static const String _colorPaletteKey = 'color_palette';
  static const String _pomodorosCountKey = 'pomodoros_count_';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Initialize storage
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Pomodoro Config
  Future<void> saveConfig(PomodoroConfig config) async {
    await _prefs.setString(_configKey, jsonEncode(config.toJson()));
  }

  PomodoroConfig? loadConfig() {
    final json = _prefs.getString(_configKey);
    if (json == null) return null;
    return PomodoroConfig.fromJson(jsonDecode(json));
  }

  // Pomodoro State
  Future<void> saveState(PomodoroState state) async {
    await _prefs.setString(_stateKey, jsonEncode(state.toJson()));
  }

  PomodoroState? loadState() {
    final json = _prefs.getString(_stateKey);
    if (json == null) return null;
    return PomodoroState.fromJson(jsonDecode(json));
  }

  // Tasks by date
  Future<void> saveTasks(DateTime date, List<Task> tasks) async {
    final key = _tasksKey + _dateKey(date);
    final json = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _prefs.setString(key, json);
  }

  List<Task> loadTasks(DateTime date) {
    final key = _tasksKey + _dateKey(date);
    final json = _prefs.getString(key);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((item) => Task.fromJson(item)).toList();
  }

  // Pomodoros count per day
  Future<void> incrementPomodorosCount(DateTime date) async {
    final key = _pomodorosCountKey + _dateKey(date);
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);
  }

  int getPomodorosCount(DateTime date) {
    final key = _pomodorosCountKey + _dateKey(date);
    return _prefs.getInt(key) ?? 0;
  }

  // Settings
  Future<void> saveLanguage(String languageCode) async {
    await _prefs.setString(_languageKey, languageCode);
  }

  String? loadLanguage() => _prefs.getString(_languageKey);

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(_soundKey, enabled);
  }

  bool getSoundEnabled() => _prefs.getBool(_soundKey) ?? true;

  Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs.setBool(_vibrationKey, enabled);
  }

  bool getVibrationEnabled() => _prefs.getBool(_vibrationKey) ?? true;

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_themeKey, mode);
    notifyListeners();
  }

  String getThemeMode() => _prefs.getString(_themeKey) ?? 'system';

  Future<void> setColorPalette(String paletteId) async {
    await _prefs.setString(_colorPaletteKey, paletteId);
    notifyListeners();
  }

  String getColorPalette() => _prefs.getString(_colorPaletteKey) ?? 'lavender';

  // Reset all data
  Future<void> resetAll() async {
    await _prefs.clear();
  }

  // Helper to create date key (YYYY-MM-DD)
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
