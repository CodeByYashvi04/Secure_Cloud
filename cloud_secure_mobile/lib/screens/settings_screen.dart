import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_secure_mobile/screens/login_screen.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  
  late bool mfaEnabled;
  late bool pushEnabled;
  late String threatStrictness;
  late bool dataSanitization;
  late bool biometricEnabled;

  @override
  void initState() {
    super.initState();
    _refreshUserData();
  }

  void _refreshUserData() {
    final user = ApiService.currentUser;
    mfaEnabled = user?['mfaEnabled'] ?? false;
    pushEnabled = user?['pushNotificationsEnabled'] ?? true;
    threatStrictness = user?['threatStrictness'] ?? 'Medium';
    dataSanitization = user?['dataSanitization'] ?? false;
    biometricEnabled = user?['biometricEnabled'] ?? false;
  }

  Future<void> _secureUpdate(String key, dynamic val, {bool requiresPassword = false}) async {
    if (requiresPassword) {
      final confirmed = await _showPasswordGuard();
      if (!confirmed) return;
    }

    setState(() => _isLoading = true);
    final success = await ApiService.updateProfile(
      mfa: key == 'mfa' ? val : null,
      notifications: key == 'notifications' ? val : null,
      threatStrictness: key == 'strictness' ? val : null,
      dataSanitization: key == 'sanitization' ? val : null,
      biometricEnabled: key == 'biometric' ? val : null,
    );

    if (mounted && success != null) {
      setState(() {
        _refreshUserData();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Security configuration updated'), backgroundColor: Color(0xFF00F0FF))
      );
    }
  }

  Future<bool> _showPasswordGuard() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDark;
    final ctrl = TextEditingController();
    bool isVerifying = false;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F1522) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade200)),
          title: Row(
            children: [
              const Icon(LucideIcons.shieldAlert, color: Color(0xFFFF3366), size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Security Verification', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Confirm your password to modify sensitive security settings.', style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.black54, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                obscureText: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Your Password',
                  labelStyle: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.grey),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1A233A) : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.grey))),
            ElevatedButton(
              onPressed: isVerifying ? null : () async {
                setModalState(() => isVerifying = true);
                await Future.delayed(const Duration(milliseconds: 800));
                if (mounted) Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F0FF), foregroundColor: const Color(0xFF0B0F19)),
              child: isVerifying ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('VERIFY'),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  void _showPanicDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F1522) : Colors.white,
        title: const Text('ACTIVATE PANIC MODE?', style: TextStyle(color: Color(0xFFFF3366), fontWeight: FontWeight.bold)),
        content: Text('This will immediately revoke all active cloud session keys and force a global logout. Use only in case of suspected breach.', 
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.grey : Colors.black54))),
          ElevatedButton(
            onPressed: () async {
               await ApiService.triggerPanicMode();
               if (mounted) {
                 Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
               }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3366)),
            child: const Text('ACTIVATE NOW'),
          ),
        ],
      ),
    );
  }

  void _showAuditLogs() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDark;

    setState(() => _isLoading = true);
    final logs = await ApiService.getAuditLogs();
    setState(() => _isLoading = false);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F1522) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security Audit Log', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Recent login attempts and security events.', style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black54, fontSize: 12)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, i) {
                  final log = logs[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(LucideIcons.monitor, color: isDark ? const Color(0xFF00F0FF) : Colors.cyan, size: 18),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['device'] ?? 'Unknown Device', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                            Text('IP: ${log['ip']} • ${DateFormat('MMM d, HH:mm').format(DateTime.parse(log['timestamp']))}', 
                                style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black54, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
        title: const Text('Digital Fortress Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildCategory('Account Security & Identity', isDark),
          _buildToggle(LucideIcons.lock, 'Multi-Factor Auth (MFA)', 'Adds a 2nd layer of protection', mfaEnabled, (v) => _secureUpdate('mfa', v, requiresPassword: true), isDark),
          _buildToggle(LucideIcons.fingerprint, 'Biometric Login', 'Use FaceID/Fingerprint for access', biometricEnabled, (v) => _secureUpdate('biometric', v), isDark),
          _buildAction(LucideIcons.key, 'Change Password', 'Update your master key', () => _showEditProfile(), isDark),
          
          const SizedBox(height: 24),
          _buildCategory('AI & Data Privacy', isDark),
          _buildAction(LucideIcons.shieldAlert, 'Threat Strictness', 'Current: $threatStrictness', () => _showStrictnessPicker(), isDark),
          _buildToggle(LucideIcons.eyeOff, 'Data Sanitization', 'Redact sensitive info from AI logs', dataSanitization, (v) => _secureUpdate('sanitization', v), isDark),
          
          const SizedBox(height: 24),
          _buildCategory('Audit & Emergencies', isDark),
          _buildAction(LucideIcons.activity, 'Security Audit Log', 'View recent login history', _showAuditLogs, isDark),
          _buildAction(LucideIcons.zap, 'Panic Mode Trigger', 'Revoke all keys instantly', _showPanicDialog, isDark, isCritical: true),
          
          const SizedBox(height: 24),
          _buildCategory('App Customization', isDark),
          _buildToggle(LucideIcons.moon, 'Dark Mode Interface', 'Save battery and eyes', isDark, (v) => themeProvider.toggleTheme(), isDark),
          _buildToggle(LucideIcons.bell, 'Real-time Alerts', 'Critical threat notifications', pushEnabled, (v) => _secureUpdate('notifications', v), isDark),

          const SizedBox(height: 40),
          _buildSignOut(theme, isDark),
          const SizedBox(height: 20),
          _buildPurgeAccount(theme, isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategory(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title.toUpperCase(), style: TextStyle(color: isDark ? const Color(0xFF00F0FF) : Colors.cyan.shade700, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _buildToggle(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1522) : Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade200),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: isDark ? const Color(0xFF4F6B92) : Colors.grey),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black54, fontSize: 12)),
        trailing: Switch(
          value: value, 
          onChanged: onChanged,
          activeColor: const Color(0xFF00F0FF),
          activeTrackColor: const Color(0xFF00F0FF).withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String title, String subtitle, VoidCallback onTap, bool isDark, {bool isCritical = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1522) : Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isCritical ? const Color(0xFFFF3366).withOpacity(0.3) : (isDark ? const Color(0xFF1A233A) : Colors.grey.shade200)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: isCritical ? const Color(0xFFFF3366) : (isDark ? const Color(0xFF4F6B92) : Colors.grey)),
        title: Text(title, style: TextStyle(color: isCritical ? const Color(0xFFFF3366) : (isDark ? Colors.white : Colors.black87), fontSize: 15, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black54, fontSize: 12)),
        trailing: Icon(LucideIcons.chevronRight, color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade300, size: 20),
      ),
    );
  }

  void _showStrictnessPicker() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F1522) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Threat Strictness', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildStrictOption('Low', 'Minimal alerts, focuses only on severe breaches.', threatStrictness == 'Low', isDark),
            _buildStrictOption('Medium', 'Standard protection. Recommended for most users.', threatStrictness == 'Medium', isDark),
            _buildStrictOption('High', 'Maximum audit. Alerts on every subtle configuration change.', threatStrictness == 'High', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStrictOption(String label, String desc, bool selected, bool isDark) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        _secureUpdate('strictness', label);
      },
      title: Text(label, style: TextStyle(color: selected ? (isDark ? const Color(0xFF00F0FF) : Colors.cyan) : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black54, fontSize: 12)),
      trailing: selected ? Icon(LucideIcons.checkCircle2, color: isDark ? const Color(0xFF00F0FF) : Colors.cyan) : null,
    );
  }

  Widget _buildSignOut(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
        icon: const Icon(LucideIcons.logOut),
        label: const Text('SECURE SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1A233A) : Colors.grey.shade100, 
          foregroundColor: isDark ? Colors.white : Colors.black87, 
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
      ),
    );
  }

  Widget _buildPurgeAccount(ThemeData theme, bool isDark) {
    return Center(
      child: TextButton(
        onPressed: () async {
          final confirmed = await _showPasswordGuard();
          if (confirmed) {
            await ApiService.deleteAccount();
            if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
          }
        },
        child: const Text('PURGE ACCOUNT PERMANENTLY', style: TextStyle(color: Color(0xFFFF3366), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  void _showEditProfile() {
    // Reuse existing logic or implement specific Change Password dialog
  }
}
