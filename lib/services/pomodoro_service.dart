import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/pomodoro_config.dart';
import '../models/pomodoro_state.dart';
import 'storage_service.dart';
import 'localization_service.dart';

// Pomodoro timer service
class PomodoroService extends ChangeNotifier {
  final StorageService _storage;
  final LocalizationService _localization;
  final FlutterLocalNotificationsPlugin _notifications;

  PomodoroConfig _config;
  PomodoroState _state;
  Timer? _timer;
  Timer? _notificationTimer;
  Timer? _vibrationTimer;
  bool _isAlarmPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  PomodoroService(this._storage, this._localization, this._notifications)
      : _config = const PomodoroConfig(),
        _state = const PomodoroState() {
    _initNotifications().then((_) => _loadFromStorage());
    _initAudioPlayer();
  }

  // Initialize audio player
  Future<void> _initAudioPlayer() async {
    try {
      // Set audio context globally
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      print('AudioPlayer initialized successfully');
    } catch (e) {
      print('Error initializing AudioPlayer: $e');
    }
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

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  // Handle notification actions
  void _handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'stop_alarm') {
      stopAlarm();
    }
  }

  // Stop alarm (vibration) and proceed to next phase
  Future<void> stopAlarmAndProceed() async {
    if (_state.status != TimerStatus.alarm) {
      print(
          'stopAlarmAndProceed called but status is not alarm: ${_state.status}');
      return;
    }

    print('Stopping alarm and proceeding to next phase...');
    print(
        'Current state before stop: seconds=${_state.secondsRemaining}, endTimestamp=${_state.endTimestampMillis}');

    // Stop alarm
    _isAlarmPlaying = false;
    _vibrationTimer?.cancel();
    await Vibration.cancel();
    await _audioPlayer.stop();
    await _notifications.cancel(1); // Cancel alarm notification
    await _notifications.cancel(0); // Cancel progress notification

    // Stop the negative timer completely
    _timer?.cancel();
    _timer = null;
    _notificationTimer?.cancel();
    _notificationTimer = null;

    // Save completed mode before transitioning
    final completedMode = _state.mode;

    print('Completed mode: $completedMode, proceeding to next phase');

    // Proceed to next phase - this will update state with new time
    _proceedToNextPhase(completedMode);
  }

  // Stop alarm only (for notification action or other uses)
  Future<void> stopAlarm() async {
    _isAlarmPlaying = false;
    _vibrationTimer?.cancel();
    await Vibration.cancel();
    await _audioPlayer.stop();
    await _notifications.cancel(1); // Cancel alarm notification
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
      } else if (remaining == 0) {
        // Timer just reached zero - trigger alarm
        _state = _state.copyWith(secondsRemaining: 0, endTimestampMillis: null);
        _onTimerComplete();
      } else {
        // Timer is now negative - continue counting in negative
        _state = _state.copyWith(secondsRemaining: remaining);
        notifyListeners();
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
    // Allow negative values for overtime counting
    return (diffMillis / 1000).ceil();
  }

  // Handle timer completion
  Future<void> _onTimerComplete({bool notify = true}) async {
    _cancelScheduledNotification();

    // Set status to alarm and continue ticking in negative
    _state = _state.copyWith(
      status: TimerStatus.alarm,
      endTimestampMillis:
          DateTime.now().millisecondsSinceEpoch, // Start counting from 0
    );

    // Play notification and vibration
    if (notify) {
      await _showAlarmNotification();
      await _playAlarmVibration();
      await _playAlarmAudio();
    }

    // Don't stop the timer - let it continue counting in negative
    notifyListeners();
    _saveState();
  }

  // Avanzar a la siguiente fase del pomodoro
  void _proceedToNextPhase(PomodoroMode completedMode) {
    print('_proceedToNextPhase called with mode: $completedMode');

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
          endTimestampMillis: null, // Clear timestamp
        );
        print('Moving to long break: ${_config.longBreakMinutes} minutes');
      } else {
        _state = _state.copyWith(
          mode: PomodoroMode.shortBreak,
          status: TimerStatus.idle,
          secondsRemaining: _config.shortBreakMinutes * 60,
          endTimestampMillis: null, // Clear timestamp
        );
        print('Moving to short break: ${_config.shortBreakMinutes} minutes');
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
        endTimestampMillis: null, // Clear timestamp
      );
      print(
          'Moving to focus: ${_config.focusMinutes} minutes, cycle: $nextCycle');
    }

    print(
        'New state - seconds: ${_state.secondsRemaining}, status: ${_state.status}');
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
    await _notifications.cancel(0);
    _notificationTimer?.cancel();

    final content = _getNotificationContent(_state.mode);
    final remainingSeconds = _calculateRemainingSeconds();
    final minutes = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final androidDetails = AndroidNotificationDetails(
      'pomodoro_progress_channel',
      'Pomodoro Timer Progress',
      channelDescription: 'Shows ongoing Pomodoro timer',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      ongoing: true,
      showProgress: true,
      maxProgress: _getDurationForMode(_state.mode),
      progress: _getDurationForMode(_state.mode) - remainingSeconds,
      onlyAlertOnce: true,
      styleInformation: BigTextStyleInformation(
        timeString,
        contentTitle: content['title'],
      ),
    );

    await _notifications.show(
      0,
      content['title'],
      timeString,
      NotificationDetails(android: androidDetails),
    );

    // Update notification every second with remaining time
    _notificationTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = _calculateRemainingSeconds();
      if (remaining > 0) {
        final mins = remaining ~/ 60;
        final secs = remaining % 60;
        final time =
            '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

        final details = AndroidNotificationDetails(
          'pomodoro_progress_channel',
          'Pomodoro Timer Progress',
          channelDescription: 'Shows ongoing Pomodoro timer',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          ongoing: true,
          showProgress: true,
          maxProgress: _getDurationForMode(_state.mode),
          progress: _getDurationForMode(_state.mode) - remaining,
          onlyAlertOnce: true,
          styleInformation: BigTextStyleInformation(
            time,
            contentTitle: content['title'],
          ),
        );

        await _notifications.show(
          0,
          content['title'],
          time,
          NotificationDetails(android: details),
        );
      }
    });
  }

  void _cancelScheduledNotification() {
    _notifications.cancel(0);
    _notificationTimer?.cancel();
  }

  // Show alarm notification with action button
  Future<void> _showAlarmNotification() async {
    final content = _getNotificationContent(_state.mode);

    final androidDetails = AndroidNotificationDetails(
      'pomodoro_alarm_channel',
      'Pomodoro Alarm',
      channelDescription: 'Alarm when Pomodoro timer completes',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false,
      enableVibration:
          false, // Vibration handled separately for continuous loop
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      actions: const [
        AndroidNotificationAction(
          'stop_alarm',
          'Detener',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);
    await _notifications.show(1, content['title'], content['body'], details);
  }

  // Play alarm vibration
  Future<void> _playAlarmVibration() async {
    if (!_storage.getVibrationEnabled()) return;

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    _isAlarmPlaying = true;
    // Vibrate continuously until stopped
    _vibrationTimer =
        Timer.periodic(const Duration(milliseconds: 1400), (_) async {
      if (_isAlarmPlaying) {
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      }
    });
    // Start first vibration immediately
    await Vibration.vibrate(
      pattern: [0, 500, 200, 500, 200, 500],
      intensities: [0, 255, 0, 255, 0, 255],
    );
  }

  // Play alarm audio
  Future<void> _playAlarmAudio() async {
    try {
      print('Attempting to play alarm audio...');
      await _audioPlayer.stop(); // Stop any previous playback
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);

      await _audioPlayer.play(AssetSource('notification/notification.mp3'));
      print('Audio playback started successfully');

      // Verify playback state
      final state = _audioPlayer.state;
      print('AudioPlayer state after play: $state');
    } catch (e, stackTrace) {
      print('Error playing alarm audio: $e');
      print('Stack trace: $stackTrace');
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
    _notificationTimer?.cancel();
    _vibrationTimer?.cancel();
    _cancelScheduledNotification();
    stopAlarm();
    _audioPlayer.dispose();
    super.dispose();
  }
}
