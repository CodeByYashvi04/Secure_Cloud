import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getActivityLogs();
    if (mounted) setState(() { _logs = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(LucideIcons.refreshCw, size: 20), onPressed: _fetchLogs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.clipboardList, size: 64, color: Color(0xFF4F6B92)),
                      const SizedBox(height: 16),
                      Text('No activity logs yet.', style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, i) => _buildLogCard(_logs[i], isDark),
                  ),
                ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, bool isDark) {
    final risk = (log['riskScore'] ?? 0) as int;
    final riskColor = risk > 70 ? const Color(0xFFFF3366)
        : risk > 40 ? const Color(0xFFF5A623)
        : const Color(0xFF00F0FF);
    final timestamp = log['timestamp'] != null
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(log['timestamp']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: riskColor, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(log['action'] ?? 'Action',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            ),
            Text(timestamp, style: const TextStyle(color: Color(0xFF4F6B92), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Service: ${log['service'] ?? 'N/A'}  •  IP: ${log['ipAddress'] ?? 'N/A'}',
            style: const TextStyle(color: Color(0xFFA0B2C6), fontSize: 13)),
        const SizedBox(height: 4),
        Text('Risk Score: $risk', style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
