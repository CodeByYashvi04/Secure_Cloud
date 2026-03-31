import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.register(name, email, password);

    setState(() => _isLoading = false);

    if (result.containsKey('token')) {
      ApiService.setToken(result['token']);
      if (result['user'] != null) {
        ApiService.setUser(Map<String, dynamic>.from(result['user']));
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? theme.primaryColor : const Color(0xFF1E293B)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join CloudSecure',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Provision your administrative security account.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFA0B2C6) : Colors.black45,
                ),
              ),
              const SizedBox(height: 40),

              // Full Name
              _buildTextField(
                label: 'Legal Full Name',
                icon: LucideIcons.user,
                theme: theme,
                isDark: isDark,
                controller: _nameController,
              ),
              const SizedBox(height: 20),

              // Email
              _buildTextField(
                label: 'Corporate Email Address',
                icon: LucideIcons.mail,
                theme: theme,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              const SizedBox(height: 20),

              // Password
              _buildPasswordField(
                label: 'Security Access Password',
                icon: LucideIcons.lock,
                theme: theme,
                isDark: isDark,
                controller: _passwordController,
              ),
              const SizedBox(height: 20),

              // Confirm Password
              _buildPasswordField(
                label: 'Confirm Access Password',
                icon: LucideIcons.lock,
                theme: theme,
                isDark: isDark,
                controller: _confirmController,
              ),
              const SizedBox(height: 40),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                        'PROVISION ACCOUNT',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    TextInputType? keyboardType,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
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

  Widget _buildPasswordField({
    required String label,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !_isPasswordVisible,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isDark ? theme.primaryColor : Colors.black38, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                color: Colors.black38,
                size: 20,
              ),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
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
