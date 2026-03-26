import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ai_chat_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _stats = {
    'riskScore': 0,
    'connectedClouds': 0,
    'activeSessions': 0,
    'totalAlerts': 0,
    'recentActivities': [],
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getStats();
    if (mounted) {
      setState(() {
        _stats = data;
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${_stats['riskScore'] > 50 ? "THREAT DETECTED" : "SECURE"}',
              style: TextStyle(
                color: _stats['riskScore'] > 50 ? const Color(0xFFFF3366) : const Color(0xFF00F0FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Security Dashboard',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: theme.primaryColor, size: 20),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRiskGauge(_stats['riskScore']),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 30),
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...(_stats['recentActivities'] as List).map((activity) {
                      return _buildActivityCard(
                        activity['action'] ?? 'Unknown Action',
                        'Recently',
                        'Service: ${activity['service']} • IP: ${activity['ipAddress']}',
                        'Risk: ${activity['riskScore']} pts',
                        activity['riskScore'] > 40 ? const Color(0xFFFF3366) : const Color(0xFF00F0FF),
                      );
                    }),
                    if ((_stats['recentActivities'] as List).isEmpty)
                      const Center(child: Text('No recent activity detected')),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AIChatScreen()),
                          );
                        },
                        icon: const Icon(LucideIcons.bot, color: Color(0xFF00F0FF)),
                        label: const Text(
                          'Ask AI Assistant',
                          style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                          side: const BorderSide(color: Color(0xFF00F0FF)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRiskGauge(int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: (score > 50 ? const Color(0xFFFF3366) : const Color(0xFF00F0FF)).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: TextStyle(
              color: score > 50 ? const Color(0xFFFF3366) : const Color(0xFF00F0FF),
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'System Risk Score'.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF4F6B92),
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildStatCard(LucideIcons.cloudRain, 'Cloud Accounts', _stats['connectedClouds'].toString(), const Color(0xFF00F0FF)),
              const SizedBox(height: 15),
              _buildStatCard(LucideIcons.shieldAlert, 'Threat Alerts', _stats['totalAlerts'].toString(), const Color(0xFFFF3366)),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            children: [
              _buildStatCard(LucideIcons.users, 'Active Sessions', _stats['activeSessions'].toString(), const Color(0xFF00F0FF)),
              const SizedBox(height: 15),
              _buildStatCard(LucideIcons.activity, 'API Requests', '1.4k', const Color(0xFF00F0FF)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4F6B92),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String action, String time, String detail, String riskText, Color riskColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: riskColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                action,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF4F6B92),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFFA0B2C6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            riskText,
            style: TextStyle(
              color: riskColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
