import 'package:flutter/material.dart';

// Timer display widget showing mm:ss
class TimerDisplay extends StatelessWidget {
  final int seconds;

  const TimerDisplay({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Text(
      timeString,
      style: Theme.of(context).textTheme.displayLarge,
    );
  }
}
