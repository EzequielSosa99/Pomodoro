import 'package:flutter/material.dart';
import '../models/pomodoro_config.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';

// Configuration bottom sheet
class ConfigSheet extends StatefulWidget {
  final PomodoroConfig initialConfig;
  final Function(PomodoroConfig) onSave;

  const ConfigSheet({
    super.key,
    required this.initialConfig,
    required this.onSave,
  });

  @override
  State<ConfigSheet> createState() => _ConfigSheetState();
}

class _ConfigSheetState extends State<ConfigSheet> {
  late TextEditingController _focusController;
  late TextEditingController _shortBreakController;
  late TextEditingController _longBreakController;
  late TextEditingController _cyclesController;

  @override
  void initState() {
    super.initState();
    _focusController = TextEditingController(
        text: widget.initialConfig.focusMinutes.toString());
    _shortBreakController = TextEditingController(
        text: widget.initialConfig.shortBreakMinutes.toString());
    _longBreakController = TextEditingController(
        text: widget.initialConfig.longBreakMinutes.toString());
    _cyclesController = TextEditingController(
        text: widget.initialConfig.cyclesBeforeLongBreak.toString());
  }

  @override
  void dispose() {
    _focusController.dispose();
    _shortBreakController.dispose();
    _longBreakController.dispose();
    _cyclesController.dispose();
    super.dispose();
  }

  void _save() {
    final newConfig = PomodoroConfig(
      focusMinutes: int.tryParse(_focusController.text) ?? 25,
      shortBreakMinutes: int.tryParse(_shortBreakController.text) ?? 5,
      longBreakMinutes: int.tryParse(_longBreakController.text) ?? 15,
      cyclesBeforeLongBreak: int.tryParse(_cyclesController.text) ?? 4,
    );
    widget.onSave(newConfig);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocalizationService>().t;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('home.config.title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _focusController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t('home.config.focusMinutes'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _shortBreakController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t('home.config.shortBreakMinutes'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _longBreakController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t('home.config.longBreakMinutes'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cyclesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t('home.config.cyclesBeforeLongBreak'),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: Text(t('home.config.save')),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
