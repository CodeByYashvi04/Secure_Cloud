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
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

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
                color: isDark ? theme.primaryColor.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? theme.primaryColor.withOpacity(0.1) : Colors.grey.shade200),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.userCheck, size: 28, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?['name'] ?? 'Authorized User',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.mail, size: 12, color: theme.primaryColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(user?['email'] ?? '', 
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.black54, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Icon(LucideIcons.shieldCheck, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('Secure File Vault', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 16),
            // Search Bar
            TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: 'Search encrypted files...',
                hintStyle: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45),
                prefixIcon: Icon(LucideIcons.search, color: theme.primaryColor, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF1A233A) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 24),
            // Upload area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade200, width: 1.5),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(LucideIcons.uploadCloud, size: 32, color: theme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text('Securely sync files to the cloud vault',
                      style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.black54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _isUploading
                      ? Column(children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          const Text('Encrypting and uploading...', style: TextStyle(color: Color(0xFF00F0FF))),
                        ])
                      : ElevatedButton.icon(
                          onPressed: _pickAndUpload,
                          icon: const Icon(LucideIcons.filePlus, size: 18),
                          label: const Text('SELECT FILE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: const Color(0xFF0B0F19),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Vault Assets (${_files.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
            const SizedBox(height: 16),
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
              ..._files.where((f) => (f['name'] ?? '').toString().toLowerCase().contains(_searchQuery)).map((f) => _buildFileRow(f)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileRow(Map<String, dynamic> f) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = f['status'] ?? 'Unknown';
    
    final name = f['name'] ?? 'Unknown';
    IconData fileIcon = LucideIcons.fileText;
    if (name.endsWith('.pdf')) fileIcon = LucideIcons.fileType;
    if (name.endsWith('.jpg') || name.endsWith('.png')) fileIcon = LucideIcons.image;
    if (name.endsWith('.zip') || name.endsWith('.rar')) fileIcon = LucideIcons.archive;

    final uploadedAt = f['uploadedAt'] != null
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(f['uploadedAt']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade200),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (isDark ? theme.primaryColor : Colors.cyan).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(fileIcon, color: isDark ? theme.primaryColor : Colors.cyan.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${_formatSize(f['size'] ?? 0)}  •  $status  •  $uploadedAt',
                    style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black54, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.download, color: isDark ? theme.primaryColor : Colors.cyan.shade700, size: 20),
            onPressed: () => ApiService.downloadFile(f['id'], name),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Color(0xFFFF3366), size: 20),
            onPressed: () => _deleteFile(f['id'], name),
          ),
        ],
      ),
    );
  }
}
