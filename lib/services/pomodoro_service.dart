import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import '../models/pomodoro_config.dart';
import '../models/pomodoro_state.dart';
import 'storage_service.dart';
import 'localization_service.dart';
import 'ad_service.dart';

// Pomodoro timer service
class PomodoroService extends ChangeNotifier {
  final StorageService _storage;
  final LocalizationService _localization;
  final FlutterLocalNotificationsPlugin _notifications;

  PomodoroConfig _config;
  PomodoroState _state;
  Timer? _timer;

  PomodoroService(this._storage, this._localization, this._notifications)
      : _config = const PomodoroConfig(),
        _state = const PomodoroState() {
    _loadFromStorage();
    _initNotifications();
  }

  PomodoroConfig get config => _config;
  PomodoroState get state => _state;

  // Initialize notifications
  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  // Load saved config and state
  void _loadFromStorage() {
    _config = _storage.loadConfig() ?? const PomodoroConfig();
    final savedState = _storage.loadState();
    if (savedState != null) {
      // Restore state but reset to idle if it was running
      _state = savedState.copyWith(status: TimerStatus.idle);
    } else {
      _state = PomodoroState(
        secondsRemaining: _config.focusMinutes * 60,
      );
    }
    notifyListeners();
  }

  // Update configuration
  Future<void> updateConfig(PomodoroConfig newConfig) async {
    _config = newConfig;
    await _storage.saveConfig(_config);

    // Reset timer with new config
    reset();
  }

  // Start timer
  void start() {
    if (_state.status == TimerStatus.running) return;

    // If idle, set initial time
    if (_state.status == TimerStatus.idle) {
      _state = _state.copyWith(
        secondsRemaining: _getDurationForMode(_state.mode),
        status: TimerStatus.running,
      );
    } else {
      // Resume from paused
      _state = _state.copyWith(status: TimerStatus.running);
    }

    _startTicking();
    _saveState();
    notifyListeners();
  }

  // Pause timer
  void pause() {
    if (_state.status != TimerStatus.running) return;
    _timer?.cancel();
    _state = _state.copyWith(status: TimerStatus.paused);
    _saveState();
    notifyListeners();
  }

  // Reset timer
  void reset() {
    _timer?.cancel();
    _state = PomodoroState(
      mode: PomodoroMode.focus,
      status: TimerStatus.idle,
      currentCycle: 1,
      secondsRemaining: _config.focusMinutes * 60,
    );
    _saveState();
    notifyListeners();
  }

  // Start the countdown
  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.secondsRemaining > 0) {
        _state = _state.copyWith(secondsRemaining: _state.secondsRemaining - 1);
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  // Handle timer completion
  Future<void> _onTimerComplete() async {
    _timer?.cancel();

    // Guardar el modo actual antes de cambiar (para el interstitial)
    final completedMode = _state.mode;

    // Play notification and vibration
    await _showNotification();
    await _playVibration();

    // Mostrar interstitial y LUEGO cambiar a la siguiente fase
    // El callback onClosed se ejecutará cuando el usuario cierre el anuncio o si no se pudo mostrar
    await AdService.instance.showInterstitialIfReady(
      onClosed: () {
        // Este callback se ejecuta DESPUÉS de que el anuncio se cierra o falla
        _proceedToNextPhase(completedMode);
      },
    );
  }

  // Avanzar a la siguiente fase del pomodoro
  void _proceedToNextPhase(PomodoroMode completedMode) {
    // Determine next mode
    if (completedMode == PomodoroMode.focus) {
      // Increment pomodoros count
      _storage.incrementPomodorosCount(DateTime.now());

      // Check if it's time for long break
      if (_state.currentCycle >= _config.cyclesBeforeLongBreak) {
        _state = PomodoroState(
          mode: PomodoroMode.longBreak,
          status: TimerStatus.idle,
          currentCycle: 1, // Reset cycle after long break
          secondsRemaining: _config.longBreakMinutes * 60,
        );
      } else {
        _state = _state.copyWith(
          mode: PomodoroMode.shortBreak,
          status: TimerStatus.idle,
          secondsRemaining: _config.shortBreakMinutes * 60,
        );
      }
    } else {
      // After any break, go back to focus
      final nextCycle =
          completedMode == PomodoroMode.longBreak ? 1 : _state.currentCycle + 1;

      _state = PomodoroState(
        mode: PomodoroMode.focus,
        status: TimerStatus.idle,
        currentCycle: nextCycle,
        secondsRemaining: _config.focusMinutes * 60,
      );
    }

    _saveState();
    notifyListeners();
  }

  // Show notification
  Future<void> _showNotification() async {
    if (!_storage.getSoundEnabled()) return;

    String title = '';
    String body = '';

    switch (_state.mode) {
      case PomodoroMode.focus:
        title = _localization.t('home.focus');
        body = _localization.t('home.notifications.focusComplete');
        break;
      case PomodoroMode.shortBreak:
      case PomodoroMode.longBreak:
        title = _state.mode == PomodoroMode.shortBreak
            ? _localization.t('home.shortBreak')
            : _localization.t('home.longBreak');
        body = _state.mode == PomodoroMode.longBreak
            ? _localization.t('home.notifications.longBreakComplete')
            : _localization.t('home.notifications.breakComplete');
        break;
    }

    const androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Timer',
      channelDescription: 'Notifications for Pomodoro timer completion',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(0, title, body, details);
  }

  // Play vibration
  Future<void> _playVibration() async {
    if (!_storage.getVibrationEnabled()) return;

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: 500);
    }
  }

  // Get duration in seconds for a mode
  int _getDurationForMode(PomodoroMode mode) {
    switch (mode) {
      case PomodoroMode.focus:
        return _config.focusMinutes * 60;
      case PomodoroMode.shortBreak:
        return _config.shortBreakMinutes * 60;
      case PomodoroMode.longBreak:
        return _config.longBreakMinutes * 60;
    }
  }

  // Save state to storage
  Future<void> _saveState() async {
    await _storage.saveState(_state);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
