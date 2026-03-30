import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class CloudMonitorScreen extends StatefulWidget {
  const CloudMonitorScreen({super.key});

  @override
  State<CloudMonitorScreen> createState() => _CloudMonitorScreenState();
}

class _CloudMonitorScreenState extends State<CloudMonitorScreen> {
  List<dynamic> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getCloudAccounts();
    if (mounted) setState(() { _accounts = data; _isLoading = false; });
  }

  IconData _iconForProvider(String provider) {
    switch (provider) {
      case 'AWS': return LucideIcons.cloud;
      case 'GCP': return LucideIcons.database;
      default: return LucideIcons.server;
    }
  }

  Color _colorForProvider(String provider) {
    switch (provider) {
      case 'AWS': return const Color(0xFFF5A623);
      case 'GCP': return const Color(0xFF4285F4);
      default: return const Color(0xFF00A4EF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Monitor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: _fetchAccounts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? const Center(child: Text('No cloud accounts found.', style: TextStyle(color: Color(0xFFA0B2C6))))
              : RefreshIndicator(
                  onRefresh: _fetchAccounts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _accounts.length,
                    itemBuilder: (context, i) => _buildCloudCard(_accounts[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountWizard,
        backgroundColor: const Color(0xFF00F0FF),
        foregroundColor: const Color(0xFF0B0F19),
        icon: const Icon(LucideIcons.plusCircle),
        label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCloudCard(Map<String, dynamic> account) {
    final status = account['status'] ?? 'Unknown';
    final isActive = status == 'Active';
    final statusColor = isActive ? const Color(0xFF00F0FF) : const Color(0xFFFF3366);
    final provider = account['provider'] ?? 'Unknown';
    final regions = (account['regions'] as List?)?.join(', ') ?? 'N/A';
    final lastSync = account['lastSync'] != null
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(account['lastSync']))
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A233A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForProvider(provider), color: _colorForProvider(provider), size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider == 'AWS' ? 'Amazon Web Services'
                        : provider == 'GCP' ? 'Google Cloud Platform'
                        : 'Microsoft Azure',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 6),
                      Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF1A233A)),
            const SizedBox(height: 12),
            Text('Regions: $regions', style: const TextStyle(color: Color(0xFFA0B2C6), fontSize: 14)),
            const SizedBox(height: 4),
            Text('Last sync: $lastSync', style: const TextStyle(color: Color(0xFFA0B2C6), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showAddAccountWizard() {
    String? selectedProvider;
    final keyCtrl = TextEditingController();
    final secretCtrl = TextEditingController();
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF0F1522),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Cloud Provider', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Connect your cloud infrastructure for real-time monitoring.', style: TextStyle(color: Color(0xFF4F6B92))),
              const SizedBox(height: 32),
              
              if (selectedProvider == null) ...[
                const Text('Select Provider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildProviderOption('AWS', LucideIcons.cloud, const Color(0xFFF5A623), () => setModalState(() => selectedProvider = 'AWS')),
                const SizedBox(height: 12),
                _buildProviderOption('GCP', LucideIcons.database, const Color(0xFF4285F4), () => setModalState(() => selectedProvider = 'GCP')),
                const SizedBox(height: 12),
                _buildProviderOption('Azure', LucideIcons.server, const Color(0xFF00A4EF), () => setModalState(() => selectedProvider = 'Azure')),
              ] else ...[
                Row(children: [
                  Icon(_iconForProvider(selectedProvider!), color: _colorForProvider(selectedProvider!), size: 20),
                  const SizedBox(width: 8),
                  Text('Configuring $selectedProvider', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(onPressed: () => setModalState(() => selectedProvider = null), child: const Text('Change')),
                ]),
                const SizedBox(height: 24),
                _buildTextField('Access Key ID / Client ID', keyCtrl),
                const SizedBox(height: 16),
                _buildTextField('Secret Access Key / Secret', secretCtrl, isPassword: true),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isVerifying ? null : () async {
                      setModalState(() => isVerifying = true);
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Account connected and initial scan started.'),
                        backgroundColor: Color(0xFF00F0FF),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      foregroundColor: const Color(0xFF0B0F19),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(isVerifying ? 'VERIFYING CREDENTIALS...' : 'CONNECT ACCOUNT', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderOption(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A233A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, color: Color(0xFF4F6B92), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A233A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
