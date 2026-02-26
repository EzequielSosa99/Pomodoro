import 'package:flutter/material.dart';

// Timer display widget showing mm:ss
class TimerDisplay extends StatelessWidget {
  final int seconds;

  const TimerDisplay({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final isNegative = seconds < 0;
    final absoluteSeconds = seconds.abs();
    final minutes = absoluteSeconds ~/ 60;
    final secs = absoluteSeconds % 60;
    final timeString =
        '${isNegative ? '-' : ''}${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Text(
      timeString,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: isNegative ? Colors.red : null,
          ),
    );
  }
}
