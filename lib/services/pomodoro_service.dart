import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:timezone/timezone.dart' as tz;
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
    _initNotifications().then((_) => _loadFromStorage());
  }

  PomodoroConfig get config => _config;
  PomodoroState get state => _state;

  void syncWithSystemTime() {
    if (_state.status != TimerStatus.running) return;

    if (_state.endTimestampMillis == null) {
      _state = _state.copyWith(status: TimerStatus.idle);
      notifyListeners();
      return;
    }

    final remaining = _calculateRemainingSeconds();
    if (remaining <= 0) {
      _state = _state.copyWith(secondsRemaining: 0, endTimestampMillis: null);
      _onTimerComplete(notify: false);
      return;
    }

    _state = _state.copyWith(secondsRemaining: remaining);
    _startTicking();
    notifyListeners();
  }

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
      _state = savedState;
      _restoreRunningState();
    } else {
      _state = PomodoroState(
        secondsRemaining: _config.focusMinutes * 60,
      );
    }
    notifyListeners();
  }

  void _restoreRunningState() {
    if (_state.status != TimerStatus.running) return;

    final endTimestamp = _state.endTimestampMillis;
    if (endTimestamp == null) {
      _state = _state.copyWith(status: TimerStatus.idle);
      return;
    }

    final remaining = _calculateRemainingSeconds();
    if (remaining <= 0) {
      _state = _state.copyWith(secondsRemaining: 0, endTimestampMillis: null);
      _onTimerComplete(notify: false);
      return;
    }

    _state = _state.copyWith(secondsRemaining: remaining);
    _scheduleCompletionNotification(endTimestamp);
    _startTicking();
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

    final endTimestamp = _computeEndTimestampMillis(_state.secondsRemaining);
    _state = _state.copyWith(endTimestampMillis: endTimestamp);
    _scheduleCompletionNotification(endTimestamp);

    _startTicking();
    _saveState();
    notifyListeners();
  }

  // Pause timer
  void pause() {
    if (_state.status != TimerStatus.running) return;
    _timer?.cancel();
    _state = _state.copyWith(
      status: TimerStatus.paused,
      secondsRemaining: _calculateRemainingSeconds(),
      endTimestampMillis: null,
    );
    _cancelScheduledNotification();
    _saveState();
    notifyListeners();
  }

  // Reset timer
  void reset() {
    _timer?.cancel();
    _cancelScheduledNotification();
    _state = PomodoroState(
      mode: PomodoroMode.focus,
      status: TimerStatus.idle,
      currentCycle: 1,
      secondsRemaining: _config.focusMinutes * 60,
      endTimestampMillis: null,
    );
    _saveState();
    notifyListeners();
  }

  // Start the countdown
  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _calculateRemainingSeconds();
      if (remaining > 0) {
        _state = _state.copyWith(secondsRemaining: remaining);
        notifyListeners();
      } else {
        _state = _state.copyWith(secondsRemaining: 0, endTimestampMillis: null);
        _onTimerComplete();
      }
    });
  }

  int _computeEndTimestampMillis(int secondsRemaining) {
    return DateTime.now().millisecondsSinceEpoch + (secondsRemaining * 1000);
  }

  int _calculateRemainingSeconds() {
    final endTimestamp = _state.endTimestampMillis;
    if (endTimestamp == null) return _state.secondsRemaining;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMillis = endTimestamp - now;
    return (diffMillis / 1000).ceil();
  }

  // Handle timer completion
  Future<void> _onTimerComplete({bool notify = true}) async {
    _timer?.cancel();
    _cancelScheduledNotification();

    // Guardar el modo actual antes de cambiar
    final completedMode = _state.mode;

    // Play notification and vibration
    if (notify) {
      await _showNotification();
      await _playVibration();
    }

    // Ir directamente a la siguiente fase (sin intersticiales por ahora)
    _proceedToNextPhase(completedMode);
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

  Map<String, String> _getNotificationContent(PomodoroMode mode) {
    String title = '';
    String body = '';

    switch (mode) {
      case PomodoroMode.focus:
        title = _localization.t('home.focus');
        body = _localization.t('home.notifications.focusComplete');
        break;
      case PomodoroMode.shortBreak:
      case PomodoroMode.longBreak:
        title = mode == PomodoroMode.shortBreak
            ? _localization.t('home.shortBreak')
            : _localization.t('home.longBreak');
        body = mode == PomodoroMode.longBreak
            ? _localization.t('home.notifications.longBreakComplete')
            : _localization.t('home.notifications.breakComplete');
        break;
    }

    return {'title': title, 'body': body};
  }

  Future<void> _scheduleCompletionNotification(int endTimestampMillis) async {
    final soundEnabled = _storage.getSoundEnabled();
    final vibrationEnabled = _storage.getVibrationEnabled();
    if (!soundEnabled && !vibrationEnabled) return;

    await _notifications.cancel(0);

    final content = _getNotificationContent(_state.mode);

    final androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Timer',
      channelDescription: 'Notifications for Pomodoro timer completion',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      sound: soundEnabled
          ? const RawResourceAndroidNotificationSound('notification')
          : null,
      vibrationPattern: vibrationEnabled
          ? Int64List.fromList([0, 500, 200, 500, 200, 500, 200, 500])
          : null,
    );

    final scheduleDate = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.local,
      endTimestampMillis,
    );

    await _notifications.zonedSchedule(
      0,
      content['title'],
      content['body'],
      scheduleDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  void _cancelScheduledNotification() {
    _notifications.cancel(0);
  }

  // Show notification
  Future<void> _showNotification() async {
    if (!_storage.getSoundEnabled()) return;

    final content = _getNotificationContent(_state.mode);

    const androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Timer',
      channelDescription: 'Notifications for Pomodoro timer completion',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: false, // La vibración se maneja por separado
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(0, content['title'], content['body'], details);
  }

  // Play vibration
  Future<void> _playVibration() async {
    if (!_storage.getVibrationEnabled()) return;

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Vibrar 5 veces: 500ms vibración, 200ms pausa
      await Vibration.vibrate(
        pattern: [0, 500, 200, 500, 200, 500, 200, 500, 200, 500],
      );
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
    _cancelScheduledNotification();
    super.dispose();
  }
}
