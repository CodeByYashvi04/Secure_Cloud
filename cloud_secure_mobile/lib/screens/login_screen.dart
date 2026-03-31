import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../main.dart'; 
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.login(email, password);
    
    if (result.containsKey('token')) {
      ApiService.setToken(result['token']);
      if (result['user'] != null) {
        ApiService.setUser(Map<String, dynamic>.from(result['user']));
      }
      if (!mounted) return;
      // Navigate immediately without clearing loading to prevent a UI flash back to Login state
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainLayout(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      if (mounted) setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Login failed. Check your connection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.shieldCheck,
                    size: 64,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'CloudSecure',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'AI-Powered Security Operations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFA0B2C6) : Colors.black45,
                  ),
                ),
                const SizedBox(height: 48),

                // Email Input
                _buildTextField(
                  controller: _emailController,
                  label: 'Corporate Email',
                  icon: LucideIcons.mail,
                  isDark: isDark,
                  theme: theme,
                ),
                const SizedBox(height: 20),

                // Password Input
                _buildTextField(
                  controller: _passwordController,
                  label: 'Security Password',
                  icon: LucideIcons.lock,
                  isDark: isDark,
                  theme: theme,
                  isPassword: true,
                ),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                    },
                    style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
                    child: const Text('Recover Access Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: const Color(0xFF0B0F19),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0B0F19),
                          ),
                        )
                      : const Text(
                          'AUTHORIZE ACCESS',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 32),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "New Security Officer? ",
                      style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.black45, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Provision Account',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isDark ? theme.primaryColor : Colors.black38, size: 20),
            suffixIcon: isPassword ? IconButton(
              icon: Icon(
                _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                color: Colors.black38,
                size: 20,
              ),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ) : null,
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
