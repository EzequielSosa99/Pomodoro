// Pomodoro timer state
enum PomodoroMode {
  focus,
  shortBreak,
  longBreak,
}

enum TimerStatus {
  idle,
  running,
  paused,
}

class PomodoroState {
  final PomodoroMode mode;
  final TimerStatus status;
  final int currentCycle; // 1-based
  final int secondsRemaining;
  final int? endTimestampMillis;

  const PomodoroState({
    this.mode = PomodoroMode.focus,
    this.status = TimerStatus.idle,
    this.currentCycle = 1,
    this.secondsRemaining = 0,
    this.endTimestampMillis,
  });

  PomodoroState copyWith({
    PomodoroMode? mode,
    TimerStatus? status,
    int? currentCycle,
    int? secondsRemaining,
    int? endTimestampMillis,
  }) =>
      PomodoroState(
        mode: mode ?? this.mode,
        status: status ?? this.status,
        currentCycle: currentCycle ?? this.currentCycle,
        secondsRemaining: secondsRemaining ?? this.secondsRemaining,
        endTimestampMillis: endTimestampMillis ?? this.endTimestampMillis,
      );

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'mode': mode.index,
        'status': status.index,
        'currentCycle': currentCycle,
        'secondsRemaining': secondsRemaining,
        'endTimestampMillis': endTimestampMillis,
      };

  // Create from JSON
  factory PomodoroState.fromJson(Map<String, dynamic> json) => PomodoroState(
        mode: PomodoroMode.values[json['mode'] ?? 0],
        status: TimerStatus.values[json['status'] ?? 0],
        currentCycle: json['currentCycle'] ?? 1,
        secondsRemaining: json['secondsRemaining'] ?? 0,
        endTimestampMillis: json['endTimestampMillis'],
      );
}
