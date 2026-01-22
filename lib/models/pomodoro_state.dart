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

  const PomodoroState({
    this.mode = PomodoroMode.focus,
    this.status = TimerStatus.idle,
    this.currentCycle = 1,
    this.secondsRemaining = 0,
  });

  PomodoroState copyWith({
    PomodoroMode? mode,
    TimerStatus? status,
    int? currentCycle,
    int? secondsRemaining,
  }) =>
      PomodoroState(
        mode: mode ?? this.mode,
        status: status ?? this.status,
        currentCycle: currentCycle ?? this.currentCycle,
        secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      );

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'mode': mode.index,
        'status': status.index,
        'currentCycle': currentCycle,
        'secondsRemaining': secondsRemaining,
      };

  // Create from JSON
  factory PomodoroState.fromJson(Map<String, dynamic> json) => PomodoroState(
        mode: PomodoroMode.values[json['mode'] ?? 0],
        status: TimerStatus.values[json['status'] ?? 0],
        currentCycle: json['currentCycle'] ?? 1,
        secondsRemaining: json['secondsRemaining'] ?? 0,
      );
}
