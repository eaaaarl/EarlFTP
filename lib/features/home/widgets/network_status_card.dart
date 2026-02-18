import 'package:flutter/material.dart';

class NetworkStatusCard extends StatelessWidget {
  final String wifiStatus;
  final String ipAddress;
  final String networkName;

  const NetworkStatusCard({
    super.key,
    required this.wifiStatus,
    required this.ipAddress,
    required this.networkName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.wifi, 'WiFi Status', wifiStatus,
                wifiStatus == 'Connected' ? Colors.green : Colors.grey),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.language, 'IP Address', ipAddress, Colors.blue),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.router, 'Network', networkName, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}