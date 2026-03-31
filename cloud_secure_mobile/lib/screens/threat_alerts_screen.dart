import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class ThreatAlertsScreen extends StatefulWidget {
  const ThreatAlertsScreen({super.key});

  @override
  State<ThreatAlertsScreen> createState() => _ThreatAlertsScreenState();
}

class _ThreatAlertsScreenState extends State<ThreatAlertsScreen> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  StreamSubscription? _threatSub;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    
    _threatSub = WebSocketService().threatStream.listen((threat) {
      if (mounted) {
        setState(() {
          _alerts.insert(0, threat);
        });
      }
    });
  }

  @override
  void dispose() {
    _threatSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getAlerts();
    if (mounted) {
      setState(() {
        _alerts = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Threat Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: _fetchAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.shieldCheck, size: 64, color: theme.primaryColor.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'System Secure',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFA0B2C6) : Colors.black54,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('No active threats detected.', style: TextStyle(color: Color(0xFF4F6B92))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAlerts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (context, i) => _buildAlertCard(_alerts[i], isDark),
                  ),
                ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, bool isDark) {
    final theme = Theme.of(context);
    final type = alert['type'] ?? 'Low';
    final severityColor = type == 'Critical' ? const Color(0xFFFF3366)
        : type == 'High' ? const Color(0xFFF5A623)
        : (isDark ? const Color(0xFF00F0FF) : Colors.cyan.shade700);
    
    final timestamp = alert['timestamp'] != null
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(alert['timestamp']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.2)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(color: severityColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(timestamp, style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert['title'] ?? 'Security Alert',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alert['description'] ?? '',
            style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(LucideIcons.activity, size: 14, color: severityColor),
              const SizedBox(width: 6),
              Text(
                'Source: ${alert['source'] ?? "Internal Engine"}',
                style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 12),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showInvestigateDialog(alert),
                style: TextButton.styleFrom(
                  foregroundColor: severityColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                child: const Text('INVESTIGATE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInvestigateDialog(Map<String, dynamic> alert) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final type = alert['type'] ?? 'Low';
    final severityColor = type == 'Critical' ? const Color(0xFFFF3366)
        : type == 'High' ? const Color(0xFFF5A623)
        : (isDark ? const Color(0xFF00F0FF) : Colors.cyan.shade700);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('THREAT ANALYSIS', 
                    style: TextStyle(color: severityColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                IconButton(icon: Icon(LucideIcons.x, color: isDark ? Colors.white : Colors.black54), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert['title'] ?? 'Security Alert', 
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            _buildSectionHeader(LucideIcons.clipboardList, 'Technical Evidence', isDark),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A233A) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Text(
                'Source IP: 45.33.22.18\nLocation: Khabarovsk, Russia\nUser-Agent: Moz-Mozilla/5.0 (Kali Linux)\nResource: s3://cloud-secure-vault-production\nTimestamp: ${alert['timestamp']}',
                style: TextStyle(color: isDark ? const Color(0xFF00F0FF) : Colors.cyan.shade800, fontFamily: 'monospace', fontSize: 13, height: 1.5),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader(LucideIcons.shieldAlert, 'Remediation Steps', isDark),
            const SizedBox(height: 16),
            _buildRemediationStep('1', 'Rotate AWS IAM keys immediately for user: "admin-svc"', isDark),
            _buildRemediationStep('2', 'Enable IP-based geo-fencing for block: 45.33.0.0/16', isDark),
            _buildRemediationStep('3', 'Isolate affected EC2 instances (i-09ab22c8)', isDark),
            
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: severityColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('MARK AS RESOLVED', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? const Color(0xFF4F6B92) : Colors.black45),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRemediationStep(String num, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: (isDark ? const Color(0xFF00F0FF) : Colors.cyan).withOpacity(0.1), shape: BoxShape.circle),
            child: Text(num, style: TextStyle(color: isDark ? const Color(0xFF00F0FF) : Colors.cyan.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.black54, fontSize: 14))),
        ],
      ),
    );
  }
}
