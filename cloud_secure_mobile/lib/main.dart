import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/threat_alerts_screen.dart';
import 'screens/cloud_monitor_screen.dart';
// import 'screens/activity_logs_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/user_dashboard_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const CloudSecureApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

class CloudSecureApp extends StatelessWidget {
  const CloudSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'CloudSecure',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,

          // Light Theme
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF0F4F8),
            primaryColor: const Color(0xFF007ACC), // Deep blue for light mode
            cardColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007ACC),
              secondary: Color(0xFFE63946),
              surface: Colors.white,
            ),
            fontFamily: 'Inter',
            useMaterial3: true,
          ),

          // Dark Theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0B0F19),
            primaryColor: const Color(0xFF00F0FF),
            cardColor: const Color(0xFF0F1522),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00F0FF),
              secondary: Color(0xFFFF3366),
              surface: Color(0xFF0F1522),
            ),
            fontFamily: 'Inter',
            useMaterial3: true,
          ),

          // Start Authentication flow at Login
          home: const LoginScreen(),
        );
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const UserDashboardScreen(), // Newly requested Vault/File dashboard
    const ThreatAlertsScreen(),
    const CloudMonitorScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.cardColor,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: isDark
              ? const Color(0xFF4F6B92)
              : Colors.grey.shade500,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 20,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.shield),
              label: 'HQ',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.folder),
              label: 'Vault',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.activity),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.cloud),
              label: 'Monitor',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
