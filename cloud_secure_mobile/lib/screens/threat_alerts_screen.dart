import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Threat Alerts', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: theme.primaryColor, size: 20),
            onPressed: _fetchAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAlerts,
              child: _alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.shieldCheck, size: 64, color: theme.primaryColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('No active threats detected', style: TextStyle(color: Color(0xFF4F6B92))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        return _buildAlertCard(
                          type: alert['type'] ?? 'Low',
                          source: alert['source'] ?? 'Unknown',
                          title: alert['title'] ?? 'Security Alert',
                          time: 'Recently', // Simplified or use a time ago package
                          ip: 'Detected from system',
                          risk: alert['riskScore'] ?? 0,
                          icon: _getIconForType(alert['type']),
                          color: _getColorForType(alert['type']),
                        );
                      },
                    ),
            ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'Critical': return LucideIcons.alertOctagon;
      case 'High': return LucideIcons.shieldAlert;
      case 'Medium': return LucideIcons.alertTriangle;
      default: return LucideIcons.info;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'Critical': return const Color(0xFFFF3366);
      case 'High': return const Color(0xFFFF8C00);
      case 'Medium': return const Color(0xFFF5A623);
      default: return const Color(0xFF00F0FF);
    }
  }

  Widget _buildAlertCard({
    required String type,
    required String source,
    required String title,
    required String time,
    required String ip,
    required int risk,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Risk $risk',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Source: $source', style: const TextStyle(color: Color(0xFFA0B2C6))),
          const SizedBox(height: 4),
          Text('Type: $type', style: const TextStyle(color: Color(0xFFA0B2C6))),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Investigate'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4F6B92)),
                  foregroundColor: const Color(0xFFA0B2C6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
