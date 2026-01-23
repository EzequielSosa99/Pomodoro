import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pomodoro_state.dart';
import '../services/pomodoro_service.dart';
import '../services/localization_service.dart';
import '../widgets/timer_display.dart';
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

    IconData getModeIcon() {
      switch (state.mode) {
        case PomodoroMode.focus:
          return Icons.psychology_outlined;
        case PomodoroMode.shortBreak:
          return Icons.coffee_outlined;
        case PomodoroMode.longBreak:
          return Icons.spa_outlined;
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              _getModeColor(state.mode, context).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.timer_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Pomodoro',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mantén tu enfoque',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_outlined),
                      iconSize: 28,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                            ),
                            child: ConfigSheet(
                              initialConfig: config,
                              onSave: (newConfig) {
                                pomodoroService.updateConfig(newConfig);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mode card with icon
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getModeColor(state.mode, context),
                              _getModeColor(state.mode, context)
                                  .withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _getModeColor(state.mode, context)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              getModeIcon(),
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              getModeText(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Timer display with decorative circle
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getModeColor(state.mode, context)
                                    .withOpacity(0.2),
                                width: 8,
                              ),
                            ),
                          ),
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.5),
                            ),
                            child: Center(
                              child:
                                  TimerDisplay(seconds: state.secondsRemaining),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Cycle indicator with progress
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.repeat_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localization.t('home.cycle', params: {
                                'current': state.currentCycle.toString(),
                                'total':
                                    config.cyclesBeforeLongBreak.toString(),
                              }),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Control buttons with better design
                      _buildControlButtons(
                          context, state, pomodoroService, localization),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, PomodoroState state,
      PomodoroService service, LocalizationService localization) {
    if (state.status == TimerStatus.idle) {
      return _buildStartButton(context, service, localization);
    } else if (state.status == TimerStatus.running) {
      return Column(
        children: [
          _buildPauseButton(context, service, localization),
          const SizedBox(height: 12),
          _buildResetButton(context, service, localization),
        ],
      );
    } else {
      // Paused
      return Column(
        children: [
          _buildResumeButton(context, service, localization),
          const SizedBox(height: 12),
          _buildResetButton(context, service, localization),
        ],
      );
    }
  }

  Widget _buildStartButton(BuildContext context, PomodoroService service,
      LocalizationService localization) {
    return ElevatedButton(
      onPressed: () => service.start(),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow_rounded, size: 28),
          const SizedBox(width: 8),
          Text(
            localization.t('home.start'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton(BuildContext context, PomodoroService service,
      LocalizationService localization) {
    return ElevatedButton(
      onPressed: () => service.pause(),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pause_rounded, size: 28),
          const SizedBox(width: 8),
          Text(
            localization.t('home.pause'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeButton(BuildContext context, PomodoroService service,
      LocalizationService localization) {
    return ElevatedButton(
      onPressed: () => service.start(),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow_rounded, size: 28),
          const SizedBox(width: 8),
          Text(
            localization.t('home.resume'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, PomodoroService service,
      LocalizationService localization) {
    return OutlinedButton(
      onPressed: () => service.reset(),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh_rounded, size: 24),
          const SizedBox(width: 8),
          Text(
            localization.t('home.reset'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
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
