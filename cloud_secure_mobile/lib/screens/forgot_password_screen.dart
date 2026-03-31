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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Account Recovery', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.shieldQuestion, size: 64, color: theme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Forgot access credentials?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your registered email to receive a secure recovery token.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            
            _buildTextField(
              controller: _emailCtrl,
              label: 'Administrative Email',
              icon: LucideIcons.mail,
              isDark: isDark,
              theme: theme,
              enabled: !_showResetFields,
            ),
            const SizedBox(height: 24),
            
            if (!_showResetFields)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleForgot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: const Color(0xFF0B0F19),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B0F19))) 
                    : const Text(
                        'GENERATE TOKEN',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                ),
              ),

            if (_showResetFields) ...[
              const Divider(height: 48),
              if (_generatedToken != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.alertTriangle, color: Colors.amber, size: 16),
                          SizedBox(width: 8),
                          Text('DEMO MODE: RECOVERY TOKEN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 11, letterSpacing: 1.0)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(_generatedToken!, style: TextStyle(fontFamily: 'monospace', color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('(In production, this token is dispatched via email)', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45)),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _tokenCtrl,
                label: 'Security Token',
                icon: LucideIcons.key,
                isDark: isDark,
                theme: theme,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _newPassCtrl,
                label: 'New Security Password',
                icon: LucideIcons.lock,
                isDark: isDark,
                theme: theme,
                isPassword: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF94),
                    foregroundColor: const Color(0xFF0B0F19),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B0F19))) 
                    : const Text('AUTHORIZE RESET', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required ThemeData theme,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: isPassword,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isDark ? theme.primaryColor : Colors.black38, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A233A) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
