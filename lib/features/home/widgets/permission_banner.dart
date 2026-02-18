import 'package:flutter/material.dart';

class PermissionBanner extends StatelessWidget {
  final VoidCallback onGrant;

  const PermissionBanner({super.key, required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: const Text('Permission Required', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Grant permission to view WiFi details'),
        trailing: TextButton(onPressed: onGrant, child: const Text('Grant')),
      ),
    );
  }
}