import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  List<dynamic> _files = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() => _isLoading = true);
    final files = await ApiService.getFiles();
    if (mounted) setState(() { _files = files; _isLoading = false; });
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    setState(() => _isUploading = true);

    final res = await ApiService.uploadFile(file);
    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Upload complete'),
        backgroundColor: res['file'] != null ? const Color(0xFF00F0FF) : const Color(0xFFFF3366),
      ));
      if (res['file'] != null) _fetchFiles();
    }
  }

  Future<void> _deleteFile(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteFile(id);
      _fetchFiles();
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ApiService.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(LucideIcons.refreshCw, color: theme.primaryColor, size: 20), onPressed: _fetchFiles),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user?['name'] ?? 'User'}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87),
                        ),
                        Text(user?['email'] ?? '', 
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.primaryColor)),
                        Text(
                          'Role: ${user?['role'] ?? 'User'}  •  Verified',
                          style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Secure File Vault', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            // Upload area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade300, width: 2),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.uploadCloud, size: 48, color: theme.primaryColor),
                  const SizedBox(height: 16),
                  Text('Tap to select and upload files securely',
                      style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.black54)),
                  const SizedBox(height: 16),
                  _isUploading
                      ? Column(children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          const Text('Encrypting and uploading...', style: TextStyle(color: Color(0xFF00F0FF))),
                        ])
                      : ElevatedButton.icon(
                          onPressed: _pickAndUpload,
                          icon: const Icon(LucideIcons.filePlus),
                          label: const Text('Select File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: const Color(0xFF0B0F19),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Uploaded Files (${_files.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_files.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No files uploaded yet. Upload your first secure file!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.grey)),
              ))
            else
              ..._files.map((f) => _buildFileRow(f)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileRow(Map<String, dynamic> f) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = f['status'] ?? 'Unknown';
    final statusColor = status == 'Encrypted' ? const Color(0xFF00F0FF)
        : status == 'Scanning' ? const Color(0xFFF5A623)
        : const Color(0xFFFF3366);
    final uploadedAt = f['uploadedAt'] != null
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(f['uploadedAt']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileText, color: theme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                Text('${_formatSize(f['size'] ?? 0)}  •  $status  •  $uploadedAt',
                    style: TextStyle(color: statusColor, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Color(0xFFFF3366), size: 20),
            onPressed: () => _deleteFile(f['id'], f['name'] ?? 'this file'),
          ),
        ],
      ),
    );
  }
}
