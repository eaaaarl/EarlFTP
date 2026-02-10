import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isServerRunning = false;
  final String _wifiStatus = 'Connected';
  final String _ipAddress = '192.168.1.100';
  final String _networkName = 'MyHomeWiFi';
  final String _serverUrl = 'ftp://192.168.1.100:2121';
  final String _userId = 'admin';
  final String _password = 'admin123';
  bool _anonymousAccess = false;
  final String _rootFolder = '/storage/emulated/0/';

  void _toggleServer() {
    setState(() {
      _isServerRunning = !_isServerRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FTP Server'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Network Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Network Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.wifi,
                      'WiFi Status',
                      _wifiStatus,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.language,
                      'IP Address',
                      _ipAddress,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.router,
                      'Network',
                      _networkName,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Start/Stop Server Button
            ElevatedButton(
              onPressed: _toggleServer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isServerRunning ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(
                    _isServerRunning ? 'Stop Server' : 'Start Server',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Server Details (shown only when server is running)
            if (_isServerRunning) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Server Running',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildServerDetailRow('Server URL', _serverUrl, true),
                      const Divider(height: 24),
                      _buildServerDetailRow('User ID', _userId, true),
                      const Divider(height: 24),
                      _buildServerDetailRow('Password', _password, true),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Anonymous Access',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Switch(
                            value: _anonymousAccess,
                            onChanged: (value) {
                              setState(() {
                                _anonymousAccess = value;
                              });
                            },
                            activeThumbColor: Colors.green,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildServerDetailRow('Root Folder', _rootFolder, false),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            // Handle folder selection
                          },
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Change Folder'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServerDetailRow(String label, String value, bool showCopy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showCopy)
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  // Handle copy to clipboard
                },
                color: Colors.blue,
                tooltip: 'Copy',
              ),
          ],
        ),
      ],
    );
  }
}
