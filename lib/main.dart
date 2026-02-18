import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:ui' as ui;
import 'config/theme.dart';
import 'services/storage_service.dart';
import 'services/localization_service.dart';
import 'services/pomodoro_service.dart';
import 'services/ad_service.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';

/// Detecta el idioma del sistema y retorna un código soportado
String _detectSystemLanguage() {
  // Idiomas soportados por la app
  const supportedLanguages = ['en', 'es', 'pt'];

  // Obtener el idioma del sistema
  final systemLocale = ui.PlatformDispatcher.instance.locale;
  final languageCode = systemLocale.languageCode;

  // Si el idioma del sistema está soportado, usarlo
  if (supportedLanguages.contains(languageCode)) {
    return languageCode;
  }

  // Fallback a inglés si el idioma no está soportado
  return 'en';
}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureLocalTimeZone();

  // Initialize services
  final storage = await StorageService.init();

  // Detectar idioma: primero intentar cargar el guardado, si no existe usar el del sistema
  String savedLanguage = storage.loadLanguage() ?? _detectSystemLanguage();

  // Si es la primera vez (no hay idioma guardado), guardar el detectado
  if (storage.loadLanguage() == null) {
    await storage.saveLanguage(savedLanguage);
  }

  final localization = LocalizationService(savedLanguage);
  await localization.setLanguage(savedLanguage);

  final notifications = FlutterLocalNotificationsPlugin();

  // Initialize AdMob
  await AdService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: storage),
        ChangeNotifierProvider<LocalizationService>.value(value: localization),
        ChangeNotifierProvider<AdService>.value(value: AdService.instance),
        ChangeNotifierProxyProvider<LocalizationService, PomodoroService>(
          create: (context) =>
              PomodoroService(storage, localization, notifications),
          update: (context, localization, previous) =>
              previous ?? PomodoroService(storage, localization, notifications),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PomodoroService>().syncWithSystemTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final themeMode = storage.getThemeMode();
    final paletteId = storage.getColorPalette();
    final palette = AppPalettes.getById(paletteId);

    ThemeMode selectedThemeMode;
    switch (themeMode) {
      case 'light':
        selectedThemeMode = ThemeMode.light;
        break;
      case 'dark':
        selectedThemeMode = ThemeMode.dark;
        break;
      default:
        selectedThemeMode = ThemeMode.system;
    }

    return MaterialApp(
      title: 'Pomodoro Timer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(palette),
      darkTheme: AppTheme.getDarkTheme(palette),
      themeMode: selectedThemeMode,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationService>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            selectedIcon: const Icon(Icons.timer),
            label: localization.t('nav.home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: localization.t('nav.calendar'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: localization.t('nav.settings'),
          ),
        ],
      ),
    );
  }
}
