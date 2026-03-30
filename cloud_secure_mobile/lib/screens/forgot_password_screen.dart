import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  
  bool _isLoading = false;
  String? _generatedToken; // Mocked for demo
  bool _showResetFields = false;

  Future<void> _handleForgot() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    final res = await ApiService.forgotPassword(_emailCtrl.text);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['token'] != null) {
          _generatedToken = res['token'];
          _showResetFields = true;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset token generated!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
        }
      });
    }
  }

  Future<void> _handleReset() async {
    if (_tokenCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);

    final res = await ApiService.resetPassword(_tokenCtrl.text, _newPassCtrl.text);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Done')));
      if (res['message'] != null && res['message'].contains('successful')) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Password Recovery'), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(LucideIcons.shieldQuestion, size: 80, color: Color(0xFF00F0FF)),
            const SizedBox(height: 24),
            const Text(
              'Forgot your password?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email to receive a recovery token.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF4F6B92)),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(LucideIcons.mail),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              enabled: !_showResetFields,
            ),
            const SizedBox(height: 16),
            
            if (!_showResetFields)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleForgot,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: theme.primaryColor,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Color(0xFF0B0F19)) 
                    : const Text(
                        'GET RECOVERY TOKEN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B0F19), // Dark text to contrast cyan button
                        ),
                      ),
                ),
              ),

            if (_showResetFields) ...[
              const Divider(height: 48),
              if (_generatedToken != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('DEMO MODE: Reset Token', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                      SelectableText(_generatedToken!, style: const TextStyle(fontFamily: 'monospace')),
                      const Text('(In production, this would be in your email)', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              TextField(
                controller: _tokenCtrl,
                decoration: InputDecoration(
                  labelText: 'Recovery Token',
                  prefixIcon: const Icon(LucideIcons.key),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(LucideIcons.lock),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFF00FF94),
                    foregroundColor: Colors.black,
                  ),
                  child: _isLoading ? const CircularProgressIndicator() : const Text('RESET PASSWORD'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
