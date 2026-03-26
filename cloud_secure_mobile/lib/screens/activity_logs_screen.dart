import 'package:flutter/material.dart';

class ActivityLogsScreen extends StatelessWidget {
  const ActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildLog(
            action: 'Login Successful',
            user: 'admin',
            time: '10:45 AM',
            detail: 'AWS Console via 192.168.1.1',
          ),
          _buildLog(
            action: 'API Key Generated',
            user: 'admin',
            time: '11:12 AM',
            detail: 'S3 Read Access Key',
          ),
          _buildLog(
            action: 'Data Export',
            user: 'user_dev',
            time: '1:30 PM',
            detail: 'Downloaded 50MB from Bucket',
          ),
          _buildLog(
            action: 'Failed Login',
            user: 'unknown',
            time: '2:15 PM',
            detail: 'Azure AD via 45.33.22.1',
          ),
        ],
      ),
    );
  }

  Widget _buildLog({
    required String action,
    required String user,
    required String time,
    required String detail,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1522),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Color(0xFF4F6B92), width: 2),
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
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFFA0B2C6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'User: $user',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFF4F6B92),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
