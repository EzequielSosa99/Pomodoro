// Pomodoro configuration model
class PomodoroConfig {
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int cyclesBeforeLongBreak;

  const PomodoroConfig({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.cyclesBeforeLongBreak = 4,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'focusMinutes': focusMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'cyclesBeforeLongBreak': cyclesBeforeLongBreak,
      };

  // Create from JSON
  factory PomodoroConfig.fromJson(Map<String, dynamic> json) => PomodoroConfig(
        focusMinutes: json['focusMinutes'] ?? 25,
        shortBreakMinutes: json['shortBreakMinutes'] ?? 5,
        longBreakMinutes: json['longBreakMinutes'] ?? 15,
        cyclesBeforeLongBreak: json['cyclesBeforeLongBreak'] ?? 4,
      );

  PomodoroConfig copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? cyclesBeforeLongBreak,
  }) =>
      PomodoroConfig(
        focusMinutes: focusMinutes ?? this.focusMinutes,
        shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
        longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
        cyclesBeforeLongBreak:
            cyclesBeforeLongBreak ?? this.cyclesBeforeLongBreak,
      );
}
