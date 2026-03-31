import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/threat_alerts_screen.dart';
import 'screens/cloud_monitor_screen.dart';
// import 'screens/activity_logs_screen.dart';
import 'dart:async';
import 'screens/settings_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'services/websocket_service.dart';

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
            primaryColor: const Color(0xFF00F0FF),
            scaffoldBackgroundColor: Colors.white,
            cardColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
              iconTheme: IconThemeData(color: Color(0xFF1E293B)),
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00F0FF),
              secondary: Color(0xFFFF3366),
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF00F0FF),
              unselectedItemColor: Color(0xFF64748B),
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
  int _unreadAlerts = 0;
  StreamSubscription? _threatSub;

  @override
  void initState() {
    super.initState();
    // Connect to WebSockets for real-time alerts
    WebSocketService().connect();
    
    _threatSub = WebSocketService().threatStream.listen((threat) {
      if (mounted) {
        setState(() => _unreadAlerts++);
        
        final title = threat['title'] ?? 'New Threat Detected!';
        final desc = threat['description'] ?? 'Check your alerts tab immediately.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(desc, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF3366),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                setState(() => _currentIndex = 2); // Switch to Alerts tab
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _threatSub?.cancel();
    super.dispose();
  }

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
              if (index == 2) {
                _unreadAlerts = 0; // Clear badges when visiting Alerts
              }
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
          items: [
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.shield),
              label: 'HQ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.folder),
              label: 'Vault',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(LucideIcons.activity),
                  if (_unreadAlerts > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3366),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _unreadAlerts > 9 ? '9+' : _unreadAlerts.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.cloud),
              label: 'Monitor',
            ),
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
