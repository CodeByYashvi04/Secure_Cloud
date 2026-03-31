import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = account['status'] ?? 'Unknown';
    final isActive = status == 'Active';
    final provider = account['provider'] ?? 'Unknown';
    
    final metrics = account['pulseMetrics'] ?? {
      'resourceCount': 0, 'threatLevel': 'Low', 'complianceScore': 100,
      'activeAssets': {'compute': 0, 'storage': 0, 'identity': 0}
    };

    final threatColor = metrics['threatLevel'] == 'Critical' ? const Color(0xFFFF3366) 
                      : metrics['threatLevel'] == 'Medium' ? Colors.orange 
                      : const Color(0xFF00F0FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade200),
        boxShadow: isDark ? [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? const Color(0xFF1A233A).withOpacity(0.5) : Colors.grey.shade50,
              child: Row(
                children: [
                   _PulseIndicator(isActive: isActive),
                   const SizedBox(width: 8),
                   Text(status.toUpperCase(), style: TextStyle(color: isActive ? (isDark ? const Color(0xFF00F0FF) : Colors.cyan.shade700) : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                   const Spacer(),
                   Text('ID: ${account['accountId'] ?? 'N/A'}', style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 10, fontFamily: 'monospace')),
                ],
              ),
            ),
            
            Padding(
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
                          Text(provider == 'AWS' ? 'Amazon Web Services' : provider == 'GCP' ? 'Google Cloud' : 'Microsoft Azure',
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Monitoring ${metrics['resourceCount']} active resources', style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Security Compliance', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('${metrics['complianceScore']}%', style: TextStyle(color: threatColor, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: metrics['complianceScore'] / 100,
                      backgroundColor: isDark ? const Color(0xFF1A233A) : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(threatColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('Compute', metrics['activeAssets']['compute'].toString(), LucideIcons.cpu, isDark),
                      _buildMiniStat('Storage', metrics['activeAssets']['storage'].toString(), LucideIcons.hardDrive, isDark),
                      _buildMiniStat('Identity', metrics['activeAssets']['identity'].toString(), LucideIcons.userCheck, isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: isDark ? const Color(0xFF4F6B92) : Colors.black38, size: 18),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black54, fontSize: 10)),
      ],
    );
  }

  void _showAddAccountWizard() {
    String? selectedProvider;
    bool isVerifying = false;
    String errorMessage = '';

    final awsAccessCtrl = TextEditingController();
    final awsSecretCtrl = TextEditingController();
    final gcpProjectCtrl = TextEditingController();
    final gcpEmailCtrl = TextEditingController();
    final gcpKeyCtrl = TextEditingController();
    final azureTenantCtrl = TextEditingController();
    final azureClientCtrl = TextEditingController();
    final azureSecretCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Cloud Provider', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Connect your cloud infrastructure via IAM credentials.', style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black54)),
                const SizedBox(height: 24),
                
                if (selectedProvider == null) ...[
                  Text('Select Provider', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildProviderOption('AWS', LucideIcons.cloud, const Color(0xFFF5A623), () => setModalState(() => selectedProvider = 'AWS'), isDark),
                  const SizedBox(height: 12),
                  _buildProviderOption('GCP', LucideIcons.database, const Color(0xFF4285F4), () => setModalState(() => selectedProvider = 'GCP'), isDark),
                  const SizedBox(height: 12),
                  _buildProviderOption('Azure', LucideIcons.server, const Color(0xFF00A4EF), () => setModalState(() => selectedProvider = 'Azure'), isDark),
                ] else ...[
                  Row(children: [
                    Icon(_iconForProvider(selectedProvider!), color: _colorForProvider(selectedProvider!), size: 20),
                    const SizedBox(width: 8),
                    Text('Configuring $selectedProvider', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
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
                            _buildTextField('AWS Access Key ID', awsAccessCtrl, isDark),
                            const SizedBox(height: 16),
                            _buildTextField('AWS Secret Access Key', awsSecretCtrl, isDark, isPassword: true),
                          ] else if (selectedProvider == 'GCP') ...[
                            _buildTextField('Project ID', gcpProjectCtrl, isDark),
                            const SizedBox(height: 16),
                            _buildTextField('Service Account Email', gcpEmailCtrl, isDark),
                            const SizedBox(height: 16),
                            _buildTextField('Private Key (Paste entire block with -----BEGIN...)', gcpKeyCtrl, isDark, isPassword: true, maxLines: 5),
                          ] else if (selectedProvider == 'Azure') ...[
                            _buildTextField('Directory (Tenant) ID', azureTenantCtrl, isDark),
                            const SizedBox(height: 16),
                            _buildTextField('Application (Client) ID', azureClientCtrl, isDark),
                            const SizedBox(height: 16),
                            _buildTextField('Client Secret', azureSecretCtrl, isDark, isPassword: true),
                          ],
                          
                          if (errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFFF3366).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
                            _fetchAccounts(); 
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
                        disabledBackgroundColor: const Color(0xFF00F0FF).withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        );
      },
    );
  }

  Widget _buildProviderOption(String label, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A233A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? color.withOpacity(0.3) : Colors.grey.shade200),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(LucideIcons.chevronRight, color: isDark ? const Color(0xFF4F6B92) : Colors.grey.shade300, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, bool isDark, {bool isPassword = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: isPassword && maxLines == 1,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 13, fontFamily: 'monospace'),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF1A233A) : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  final bool isActive;
  const _PulseIndicator({required this.isActive});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const Icon(Icons.circle, size: 8, color: Colors.grey);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00F0FF).withOpacity(1.0 - _controller.value),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withOpacity(1.0 - _controller.value),
                blurRadius: 10 * _controller.value,
                spreadRadius: 4 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
