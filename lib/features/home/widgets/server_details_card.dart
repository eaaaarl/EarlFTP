import 'package:flutter/material.dart';

class ServerDetailsCard extends StatelessWidget {
  final String url;
  final int port;
  final String userId;
  final String password;
  final String rootFolder;
  final bool anonymousAccess;
  final Function(String) onCopy;
  final Function(bool) onAnonymousChanged;

  const ServerDetailsCard({
    super.key,
    required this.url,
    required this.port,
    required this.userId,
    required this.password,
    required this.rootFolder,
    required this.anonymousAccess,
    required this.onCopy,
    required this.onAnonymousChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow('Server URL', url, true),
            const Divider(),
            _buildDetailRow('Port', port.toString(), true),
            const Divider(),
            _buildDetailRow('User ID', userId, true),
            const Divider(),
            _buildDetailRow('Password', password, true),
            const Divider(),
            SwitchListTile(
              title: const Text('Anonymous Access', style: TextStyle(fontSize: 14)),
              value: anonymousAccess,
              onChanged: onAnonymousChanged,
              activeThumbColor: Colors.green,
            ),
            const Divider(),
            _buildDetailRow('Root Folder', rootFolder, false),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool showCopy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        if (showCopy)
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.blue),
            onPressed: () => onCopy(value),
          ),
      ],
    );
  }
}