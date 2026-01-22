import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pomodoro_state.dart';
import '../services/pomodoro_service.dart';
import '../services/localization_service.dart';
import '../widgets/timer_display.dart';
import '../widgets/primary_button.dart';
import '../widgets/config_sheet.dart';

// Home screen with Pomodoro timer
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pomodoroService = context.watch<PomodoroService>();
    final localization = context.watch<LocalizationService>();
    final state = pomodoroService.state;
    final config = pomodoroService.config;

    String getModeText() {
      switch (state.mode) {
        case PomodoroMode.focus:
          return localization.t('home.focus');
        case PomodoroMode.shortBreak:
          return localization.t('home.shortBreak');
        case PomodoroMode.longBreak:
          return localization.t('home.longBreak');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('home.title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => ConfigSheet(
                  initialConfig: config,
                  onSave: (newConfig) {
                    pomodoroService.updateConfig(newConfig);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mode indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _getModeColor(state.mode, context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getModeText(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
              const SizedBox(height: 40),

              // Timer display
              TimerDisplay(seconds: state.secondsRemaining),
              const SizedBox(height: 20),

              // Cycle indicator
              Text(
                localization.t('home.cycle', params: {
                  'current': state.currentCycle.toString(),
                  'total': config.cyclesBeforeLongBreak.toString(),
                }),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 60),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state.status == TimerStatus.idle)
                    PrimaryButton(
                      text: localization.t('home.start'),
                      onPressed: () => pomodoroService.start(),
                    ),
                  if (state.status == TimerStatus.running)
                    PrimaryButton(
                      text: localization.t('home.pause'),
                      onPressed: () => pomodoroService.pause(),
                    ),
                  if (state.status == TimerStatus.paused) ...[
                    PrimaryButton(
                      text: localization.t('home.resume'),
                      onPressed: () => pomodoroService.start(),
                    ),
                    const SizedBox(width: 12),
                    PrimaryButton(
                      text: localization.t('home.reset'),
                      onPressed: () => pomodoroService.reset(),
                      isSecondary: true,
                    ),
                  ],
                ],
              ),
              if (state.status != TimerStatus.idle &&
                  state.status != TimerStatus.paused) ...[
                const SizedBox(height: 12),
                PrimaryButton(
                  text: localization.t('home.reset'),
                  onPressed: () => pomodoroService.reset(),
                  isSecondary: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getModeColor(PomodoroMode mode, BuildContext context) {
    switch (mode) {
      case PomodoroMode.focus:
        return Theme.of(context).colorScheme.primary;
      case PomodoroMode.shortBreak:
        return const Color(0xFF22C55E); // Success color
      case PomodoroMode.longBreak:
        return const Color(0xFF3B82F6); // Light blue
    }
  }
}
