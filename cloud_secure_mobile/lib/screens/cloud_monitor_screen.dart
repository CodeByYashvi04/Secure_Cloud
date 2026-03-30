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
    bool isVerifying = false;
    String errorMessage = '';

    // AWS
    final awsAccessCtrl = TextEditingController();
    final awsSecretCtrl = TextEditingController();
    
    // GCP
    final gcpProjectCtrl = TextEditingController();
    final gcpEmailCtrl = TextEditingController();
    final gcpKeyCtrl = TextEditingController();

    // Azure
    final azureTenantCtrl = TextEditingController();
    final azureClientCtrl = TextEditingController();
    final azureSecretCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
              const Text('Connect your cloud infrastructure via IAM credentials.', style: TextStyle(color: Color(0xFF4F6B92))),
              const SizedBox(height: 24),
              
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
                  TextButton(onPressed: () => setModalState(() { selectedProvider = null; errorMessage = ''; }), child: const Text('Change')),
                ]),
                const SizedBox(height: 16),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedProvider == 'AWS') ...[
                          _buildTextField('AWS Access Key ID', awsAccessCtrl),
                          const SizedBox(height: 16),
                          _buildTextField('AWS Secret Access Key', awsSecretCtrl, isPassword: true),
                        ] else if (selectedProvider == 'GCP') ...[
                          _buildTextField('Project ID', gcpProjectCtrl),
                          const SizedBox(height: 16),
                          _buildTextField('Service Account Email', gcpEmailCtrl),
                          const SizedBox(height: 16),
                          _buildTextField('Private Key (Paste entire block with -----BEGIN...)', gcpKeyCtrl, isPassword: true, maxLines: 5),
                        ] else if (selectedProvider == 'Azure') ...[
                          _buildTextField('Directory (Tenant) ID', azureTenantCtrl),
                          const SizedBox(height: 16),
                          _buildTextField('Application (Client) ID', azureClientCtrl),
                          const SizedBox(height: 16),
                          _buildTextField('Client Secret', azureSecretCtrl, isPassword: true),
                        ],
                        
                        if (errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFFF3366).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.alertCircle, color: Color(0xFFFF3366), size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(errorMessage, style: const TextStyle(color: Color(0xFFFF3366), fontSize: 12))),
                              ],
                            ),
                          )
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isVerifying ? null : () async {
                      setModalState(() { isVerifying = true; errorMessage = ''; });
                      
                      Map<String, String> payload = {};
                      if (selectedProvider == 'AWS') {
                        payload = { 'apiKey': awsAccessCtrl.text, 'apiSecret': awsSecretCtrl.text };
                      } else if (selectedProvider == 'GCP') {
                        payload = { 'projectId': gcpProjectCtrl.text, 'clientEmail': gcpEmailCtrl.text, 'privateKey': gcpKeyCtrl.text };
                      } else if (selectedProvider == 'Azure') {
                        payload = { 'tenantId': azureTenantCtrl.text, 'clientId': azureClientCtrl.text, 'clientSecret': azureSecretCtrl.text };
                      }

                      try {
                        await ApiService.addCloudAccount(selectedProvider!, payload);
                        if (mounted) {
                          Navigator.pop(context);
                          _fetchAccounts(); // Refresh the list
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Row(
                              children: [
                                const Icon(LucideIcons.checkCircle, color: Colors.white),
                                const SizedBox(width: 12),
                                Text('$selectedProvider Verified & Linked!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            backgroundColor: const Color(0xFF00F0FF),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      } catch (e) {
                         setModalState(() => errorMessage = e.toString());
                      } finally {
                         setModalState(() => isVerifying = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      foregroundColor: const Color(0xFF0B0F19),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                    ),
                    child: isVerifying
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF0B0F19), strokeWidth: 2))
                        : const Text('VERIFY & CONNECT', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isPassword = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: isPassword && maxLines == 1,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
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
