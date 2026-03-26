import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CloudMonitorScreen extends StatelessWidget {
  const CloudMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Monitor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCloudCard(
            provider: 'Amazon Web Services',
            status: 'Active',
            regions: 'us-east-1, eu-west-1',
            icon: LucideIcons.cloud,
            color: const Color(0xFFF5A623),
          ),
          _buildCloudCard(
            provider: 'Google Cloud',
            status: 'Active',
            regions: 'us-central1',
            icon: LucideIcons.database,
            color: const Color(0xFF4285F4),
          ),
          _buildCloudCard(
            provider: 'Microsoft Azure',
            status: 'Issues Detected',
            regions: 'eastus',
            icon: LucideIcons.server,
            color: const Color(0xFF00A4EF),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudCard({
    required String provider,
    required String status,
    required String regions,
    required IconData icon,
    required Color color,
  }) {
    final bool isActive = status == 'Active';
    final Color statusColor = isActive ? const Color(0xFF00F0FF) : const Color(0xFFFF3366);

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
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF1A233A)),
            const SizedBox(height: 12),
            Text(
              'Regions: $regions',
              style: const TextStyle(color: Color(0xFFA0B2C6), fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Last sync: 2 min ago',
              style: TextStyle(color: Color(0xFFA0B2C6), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
