import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_secure_mobile/screens/login_screen.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // to read ThemeProvider

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ignore: unused_field
  bool _isLoading = false;
  
  late bool mfaEnabled;
  late bool pushEnabled;

  @override
  void initState() {
    super.initState();
    final user = ApiService.currentUser;
    mfaEnabled = user?['mfaEnabled'] ?? false;
    pushEnabled = user?['pushNotificationsEnabled'] ?? true;
  }

  Future<void> _updatePref(String key, bool val) async {
    setState(() => _isLoading = true);
    await ApiService.updateProfile(
      mfa: key == 'mfa' ? val : null,
      notifications: key == 'notifications' ? val : null,
    );
    if (mounted) {
      setState(() {
        if (key == 'mfa') mfaEnabled = val;
        if (key == 'notifications') pushEnabled = val;
        _isLoading = false;
      });
    }
  }

  void _showEditProfile() {
    final user = ApiService.currentUser;
    final nameCtrl = TextEditingController(text: user?['name']);
    final emailCtrl = TextEditingController(text: user?['email']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ApiService.updateProfile(name: nameCtrl.text, email: emailCtrl.text);
              if (mounted) {
                Navigator.pop(context);
                setState(() {}); // Refresh UI
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings & Security', 
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Account', theme),
          _buildActionItem(LucideIcons.user, 'Profile Details', theme, isDark, onTap: _showEditProfile),
          _buildToggleItem(LucideIcons.lock, 'Multi-Factor Auth', mfaEnabled, (val) => _updatePref('mfa', val), theme, isDark),
          const SizedBox(height: 24),
          
          _buildSectionHeader('Preferences', theme),
          _buildToggleItem(LucideIcons.bell, 'Push Notifications', pushEnabled, (val) {
            setState(() => pushEnabled = val);
          }, theme, isDark),
          
          _buildToggleItem(LucideIcons.moon, 'Dark Mode', isDark, (val) {
            themeProvider.toggleTheme();
          }, theme, isDark),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Advanced Security', theme),
          _buildActionItem(LucideIcons.shield, 'AI Threat Strictness', theme, isDark),
          _buildActionItem(LucideIcons.key, 'API Keys', theme, isDark),
          const SizedBox(height: 24),
          
          // Added a sign out option
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: Icon(LucideIcons.logOut, color: theme.colorScheme.secondary),
              label: Text('Sign Out', style: TextStyle(color: theme.colorScheme.secondary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.secondary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, ThemeData theme, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: isDark ? const Color(0xFF4F6B92) : Colors.black54),
                const SizedBox(width: 16),
                Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16)),
              ],
            ),
            Icon(LucideIcons.chevronRight, color: isDark ? const Color(0xFF4F6B92) : Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(IconData icon, String title, bool value, ValueChanged<bool> onChanged, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? const Color(0xFF4F6B92) : Colors.black54),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16)),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: isDark ? Colors.white : theme.primaryColor,
            activeTrackColor: isDark ? theme.primaryColor : theme.primaryColor.withValues(alpha: 0.5),
            inactiveTrackColor: isDark ? const Color(0xFF1A233A) : Colors.grey.shade300,
            inactiveThumbColor: isDark ? const Color(0xFF4F6B92) : Colors.grey,
          ),
        ],
      ),
    );
  }

//   Widget _buildSectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: Text(
//         title.toUpperCase(),
//         style: const TextStyle(
//           color: Color(0xFF00F0FF),
//           fontSize: 14,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1,
//         ),
//       ),
//     );
//   }

//   Widget _buildActionItem(IconData icon, String title) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0F1522),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF1A233A)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: const Color(0xFF4F6B92)),
//               const SizedBox(width: 16),
//               Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
//             ],
//           ),
//           const Icon(LucideIcons.chevronRight, color: Color(0xFF4F6B92)),
//         ],
//       ),
//     );
//   }

//   Widget _buildToggleItem(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0F1522),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFF1A233A)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: const Color(0xFF4F6B92)),
//               const SizedBox(width: 16),
//               Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
//             ],
//           ),
//           Switch(
//             value: value,
//             onChanged: onChanged,
//             activeThumbColor: Colors.white,
//             activeTrackColor: const Color(0xFF00F0FF),
//             inactiveTrackColor: const Color(0xFF1A233A),
//             inactiveThumbColor: const Color(0xFF4F6B92),
//           ),
//         ],
//       ),
//     );
//   }
 }
