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
    final ctrl = TextEditingController();
    bool isVerifying = false;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0F1522),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1A233A))),
          title: const Row(
            children: [
              Icon(LucideIcons.shieldAlert, color: Color(0xFFFF3366), size: 20),
              SizedBox(width: 12),
              Text('Security Verification', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Confirm your password to modify sensitive security settings.', style: TextStyle(color: Color(0xFFA0B2C6), fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Your Password',
                  labelStyle: const TextStyle(color: Color(0xFF4F6B92)),
                  filled: true,
                  fillColor: const Color(0xFF1A233A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF4F6B92)))),
            ElevatedButton(
              onPressed: isVerifying ? null : () async {
                setModalState(() => isVerifying = true);
                // In a real app, verify password via API
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1522),
        title: const Text('ACTIVATE PANIC MODE?', style: TextStyle(color: Color(0xFFFF3366), fontWeight: FontWeight.bold)),
        content: const Text('This will immediately revoke all active cloud session keys and force a global logout. Use only in case of suspected breach.', 
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
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
    setState(() => _isLoading = true);
    final logs = await ApiService.getAuditLogs();
    setState(() => _isLoading = false);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1522),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Security Audit Log', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Recent login attempts and security events.', style: TextStyle(color: Color(0xFF4F6B92), fontSize: 12)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, i) {
                  final log = logs[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF1A233A), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.monitor, color: Color(0xFF00F0FF), size: 18),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['device'] ?? 'Unknown Device', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('IP: ${log['ip']} • ${DateFormat('MMM d, HH:mm').format(DateTime.parse(log['timestamp']))}', 
                                style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 11)),
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
          _buildCategory('Account Security & Identity'),
          _buildToggle(LucideIcons.lock, 'Multi-Factor Auth (MFA)', 'Adds a 2nd layer of protection', mfaEnabled, (v) => _secureUpdate('mfa', v, requiresPassword: true)),
          _buildToggle(LucideIcons.fingerprint, 'Biometric Login', 'Use FaceID/Fingerprint for access', biometricEnabled, (v) => _secureUpdate('biometric', v)),
          _buildAction(LucideIcons.key, 'Change Password', 'Update your master key', () => _showEditProfile()),
          
          const SizedBox(height: 24),
          _buildCategory('AI & Data Privacy'),
          _buildAction(LucideIcons.shieldAlert, 'Threat Strictness', 'Current: $threatStrictness', () => _showStrictnessPicker()),
          _buildToggle(LucideIcons.eyeOff, 'Data Sanitization', 'Redact sensitive info from AI logs', dataSanitization, (v) => _secureUpdate('sanitization', v)),
          
          const SizedBox(height: 24),
          _buildCategory('Audit & Emergencies'),
          _buildAction(LucideIcons.activity, 'Security Audit Log', 'View recent login history', _showAuditLogs),
          _buildAction(LucideIcons.zap, 'Panic Mode Trigger', 'Revoke all keys instantly', _showPanicDialog, isCritical: true),
          
          const SizedBox(height: 24),
          _buildCategory('App Customization'),
          _buildToggle(LucideIcons.moon, 'Dark Mode Interface', 'Save battery and eyes', isDark, (v) => themeProvider.toggleTheme()),
          _buildToggle(LucideIcons.bell, 'Real-time Alerts', 'Critical threat notifications', pushEnabled, (v) => _secureUpdate('notifications', v)),

          const SizedBox(height: 40),
          _buildSignOut(theme),
          const SizedBox(height: 20),
          _buildPurgeAccount(theme),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategory(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _buildToggle(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF0F1522), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1A233A))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: const Color(0xFF4F6B92)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 12)),
        trailing: Switch(
          value: value, 
          onChanged: onChanged,
          activeColor: const Color(0xFF00F0FF),
          activeTrackColor: const Color(0xFF00F0FF).withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isCritical = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF0F1522), borderRadius: BorderRadius.circular(16), border: Border.all(color: isCritical ? const Color(0xFFFF3366).withOpacity(0.3) : const Color(0xFF1A233A))),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: isCritical ? const Color(0xFFFF3366) : const Color(0xFF4F6B92)),
        title: Text(title, style: TextStyle(color: isCritical ? const Color(0xFFFF3366) : Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 12)),
        trailing: const Icon(LucideIcons.chevronRight, color: Color(0xFF1A233A), size: 20),
      ),
    );
  }

  void _showStrictnessPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1522),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Threat Strictness', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildStrictOption('Low', 'Minimal alerts, focuses only on severe breaches.', threatStrictness == 'Low'),
            _buildStrictOption('Medium', 'Standard protection. Recommended for most users.', threatStrictness == 'Medium'),
            _buildStrictOption('High', 'Maximum audit. Alerts on every subtle configuration change.', threatStrictness == 'High'),
          ],
        ),
      ),
    );
  }

  Widget _buildStrictOption(String label, String desc, bool selected) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        _secureUpdate('strictness', label);
      },
      title: Text(label, style: TextStyle(color: selected ? const Color(0xFF00F0FF) : Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 12)),
      trailing: selected ? const Icon(LucideIcons.checkCircle2, color: Color(0xFF00F0FF)) : null,
    );
  }

  Widget _buildSignOut(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
        icon: const Icon(LucideIcons.logOut),
        label: const Text('SECURE SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A233A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _buildPurgeAccount(ThemeData theme) {
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
