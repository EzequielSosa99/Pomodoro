import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../services/localization_service.dart';
import '../config/theme.dart';

// Settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _deviceInfo = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String info = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info = '${iosInfo.name} ${iosInfo.systemVersion}';
      }

      if (mounted) {
        setState(() {
          _deviceInfo = info;
        });
      }
    } catch (e) {
      _deviceInfo = 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final localization = context.watch<LocalizationService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('settings.title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header section
          _buildHeaderSection(context, localization),
          const SizedBox(height: 24),

          // Preferencias section
          Text(
            'PREFERENCIAS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Language
          _buildSettingCard(
            context,
            title: localization.t('settings.language'),
            icon: Icons.language,
            child: SizedBox(
              width: 120,
              child: DropdownButton<String>(
                value: localization.locale.languageCode,
                isExpanded: true,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                  DropdownMenuItem(value: 'pt', child: Text('Português')),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    await localization.setLanguage(value);
                    await storage.saveLanguage(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Theme
          _buildSettingCard(
            context,
            title: localization.t('settings.theme'),
            icon: Icons.palette_outlined,
            child: SizedBox(
              width: 120,
              child: DropdownButton<String>(
                value: storage.getThemeMode(),
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: 'system',
                    child: Text(localization.t('settings.themeSystem')),
                  ),
                  DropdownMenuItem(
                    value: 'light',
                    child: Text(localization.t('settings.themeLight')),
                  ),
                  DropdownMenuItem(
                    value: 'dark',
                    child: Text(localization.t('settings.themeDark')),
                  ),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    await storage.setThemeMode(value);
                    setState(() {});
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Color Palette
          _buildColorPaletteSelector(context, storage),
          const SizedBox(height: 12),

          // Sound
          _buildSettingCard(
            context,
            title: localization.t('settings.sound'),
            icon: Icons.volume_up,
            child: Switch(
              value: storage.getSoundEnabled(),
              onChanged: (value) async {
                await storage.setSoundEnabled(value);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 12),

          // Vibration
          _buildSettingCard(
            context,
            title: localization.t('settings.vibration'),
            icon: Icons.vibration,
            child: Switch(
              value: storage.getVibrationEnabled(),
              onChanged: (value) async {
                await storage.setVibrationEnabled(value);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 24),

          // Data section
          Text(
            'DATOS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Statistics
          _buildSettingCard(
            context,
            title: 'Estadísticas',
            icon: Icons.analytics_outlined,
            child: Text(
              '${_getTotalPomodoros(storage)} 🍅',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 12),

          // Reset data
          Card(
            child: ListTile(
              leading: Icon(
                Icons.restore,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                localization.t('settings.resetData'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Eliminar todas las tareas y progreso',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () => _showResetDialog(context),
            ),
          ),
          const SizedBox(height: 24),

          // Info section
          Text(
            'INFORMACIÓN',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // App info
          _buildInfoCard(
            context,
            icon: Icons.info_outline,
            items: [
              _InfoItem('${localization.t('settings.version')}', '1.0.0'),
              _InfoItem('Desarrollador', 'Pomodoro Timer'),
              if (_deviceInfo.isNotEmpty) _InfoItem('Dispositivo', _deviceInfo),
            ],
          ),
          const SizedBox(height: 24),

          // Footer
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pomodoro Timer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Una app minimalista para mejorar tu productividad',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
      BuildContext context, LocalizationService localization) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.t('settings.title'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personaliza tu experiencia',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildColorPaletteSelector(
      BuildContext context, StorageService storage) {
    final currentPalette = storage.getColorPalette();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.color_lens_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Paleta de Colores',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppPalettes.all.map((palette) {
                final isSelected = currentPalette == palette.id;
                return GestureDetector(
                  onTap: () async {
                    await storage.setColorPalette(palette.id);
                    setState(() {});
                  },
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? palette.lightAccent
                            : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: palette.lightAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: palette.lightAccentSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          palette.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: palette.lightAccent,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required List<_InfoItem> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      items[i].label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    items[i].value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              if (i < items.length - 1) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }

  int _getTotalPomodoros(StorageService storage) {
    int total = 0;
    final now = DateTime.now();
    // Count pomodoros from last 30 days
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      total += storage.getPomodorosCount(date);
    }
    return total;
  }

  void _showResetDialog(BuildContext context) {
    final localization = context.read<LocalizationService>();
    final storage = context.read<StorageService>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.t('settings.resetData')),
        content: Text(localization.t('settings.resetConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.t('settings.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await storage.resetAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localization.t('settings.resetSuccess')),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(localization.t('settings.confirm')),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem(this.label, this.value);
}
