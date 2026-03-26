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
}
