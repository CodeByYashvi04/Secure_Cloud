import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                    child: Icon(LucideIcons.userCheck, size: 30, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back, Admin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Account Status: Verified',
                        style: TextStyle(color: theme.primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Secure File Vault',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // File Upload Area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.uploadCloud,size: 48, color: theme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Tap or drag files to upload securely',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFA0B2C6) : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File upload simulator started...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: const Color(0xFF0B0F19),
                    ),
                    child: const Text('Select File'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Uploads',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildFileRow(context, 'financial_report_Q3.pdf', '2.4 MB', 'Encrypted'),
            _buildFileRow(context, 'user_database_backup.sql', '15.1 MB', 'Scanning...'),
          ],
        ),
      ),
    );
  }

  Widget _buildFileRow(BuildContext context, String name, String size, String status) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileText, color: theme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$size • $status',
                  style: TextStyle(
                    color: status == 'Encrypted' ? const Color(0xFF00F0FF) : const Color(0xFFF5A623),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.download, color: isDark ? const Color(0xFFA0B2C6) : Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
