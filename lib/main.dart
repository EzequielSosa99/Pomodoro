import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'config/theme.dart';
import 'services/storage_service.dart';
import 'services/localization_service.dart';
import 'services/pomodoro_service.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storage = await StorageService.init();
  final savedLanguage = storage.loadLanguage() ?? 'en';
  final localization = LocalizationService(savedLanguage);
  await localization.setLanguage(savedLanguage);

  final notifications = FlutterLocalNotificationsPlugin();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<LocalizationService>.value(value: localization),
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

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final themeMode = storage.getThemeMode();

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
