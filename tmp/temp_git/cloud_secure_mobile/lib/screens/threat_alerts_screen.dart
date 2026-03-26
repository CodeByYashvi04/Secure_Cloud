import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ThreatAlertsScreen extends StatefulWidget {
  const ThreatAlertsScreen({super.key});

  @override
  State<ThreatAlertsScreen> createState() => _ThreatAlertsScreenState();
}

class _ThreatAlertsScreenState extends State<ThreatAlertsScreen> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
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
    final type = alert['type'] ?? 'Low';
    final severityColor = type == 'Critical' ? const Color(0xFFFF3366)
        : type == 'High' ? const Color(0xFFF5A623)
        : const Color(0xFF00F0FF);
    
    final timestamp = alert['timestamp'] != null
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(alert['timestamp']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: severityColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: TextStyle(color: severityColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(timestamp, style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert['title'] ?? 'Security Alert',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alert['description'] ?? '',
            style: const TextStyle(color: Color(0xFFA0B2C6), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(LucideIcons.activity, size: 14, color: severityColor),
              const SizedBox(width: 6),
              Text(
                'Source: ${alert['source'] ?? "Internal Engine"}',
                style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 12),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('INVESTIGATE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
