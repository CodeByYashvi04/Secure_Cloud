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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('System Activity Logs', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF1E293B)),
        actions: [
          IconButton(icon: Icon(LucideIcons.refreshCw, size: 20, color: theme.primaryColor), onPressed: _fetchLogs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(LucideIcons.clipboardList, size: 48, color: theme.primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text('No activity logs found.', style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.black45, fontWeight: FontWeight.bold)),
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
    final theme = Theme.of(context);
    final risk = (log['riskScore'] ?? 0) as int;
    final riskColor = risk > 70 ? const Color(0xFFFF3366)
        : risk > 40 ? const Color(0xFFF5A623)
        : (isDark ? const Color(0xFF00F0FF) : Colors.cyan.shade700);
    final timestamp = log['timestamp'] != null
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(log['timestamp']))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade100),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(log['action']?.toUpperCase() ?? 'ACTION',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
            ),
            Text(timestamp, style: TextStyle(color: isDark ? const Color(0xFF4F6B92) : Colors.black45, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(LucideIcons.globe, size: 12, color: isDark ? const Color(0xFFA0B2C6) : Colors.black38),
            const SizedBox(width: 4),
            Text('${log['service'] ?? 'N/A'}  •  ${log['ipAddress'] ?? 'N/A'}',
                style: TextStyle(color: isDark ? const Color(0xFFA0B2C6) : Colors.black54, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              height: 4,
              width: 60,
              decoration: BoxDecoration(color: riskColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text('RISK SCORE: $risk', style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
      ]),
    );
  }
}
