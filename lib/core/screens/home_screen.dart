import 'package:flutter/material.dart';
import '../services/ftp_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FtpService _ftpService = FtpService();

  bool _isServerRunning = false;
  String _wifiStatus = 'Loading...';
  String _ipAddress = 'Loading...';
  String _networkName = 'Loading...';
  String _serverUrl = '';
  final String _userId = 'admin';
  final String _password = 'admin123';
  bool _anonymousAccess = false;
  final String _rootFolder = '/storage/emulated/0/';
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    // Check if permission is already granted
    _hasLocationPermission = await _ftpService.hasLocationPermission();

    if (_hasLocationPermission) {
      // Permission already granted, just load
      _loadWifiInformation();
    } else {
      // Show explanation dialog
      _showPermissionExplanationDialog();
    }
  }

  Future<void> _showPermissionExplanationDialog() async {
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Permission Required',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
        content: const Text(
          'To display WiFi information (network name and IP address), '
              'we need location permission. This is required by Android to access WiFi details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      _loadWifiInformation();
    } else {
      setState(() {
        _wifiStatus = 'Permission Denied';
        _ipAddress = 'N/A';
        _networkName = 'N/A';
      });
    }
  }

  Future<void> _loadWifiInformation() async {
    final wifiInfo = await _ftpService.getWifiInformation();
    print('Wifi Information: $wifiInfo');

    setState(() {
      _wifiStatus = wifiInfo['wifiStatus'] ?? 'Unknown';
      _ipAddress = wifiInfo['ipAddress'] ?? 'N/A';
      _networkName = wifiInfo['networkName'] ?? 'N/A';
      _serverUrl = 'ftp://$_ipAddress:2121';
      _hasLocationPermission = wifiInfo['wifiStatus'] != 'Permission Denied';
    });
  }

  void _toggleServer() {
    // Check permission before starting server
    if (!_isServerRunning && _wifiStatus == 'Permission Denied') {
      _showPermissionExplanationDialog();
      return;
    }

    setState(() {
      _isServerRunning = !_isServerRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EarlFtp: WiFi FTP Server'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWifiInformation,
            tooltip: 'Refresh WiFi Info',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permission Warning Banner (shown when permission denied)
            if (_wifiStatus == 'Permission Denied')
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Permission Required',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Grant permission to view WiFi details',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _checkPermissionAndLoad,
                        child: const Text('Grant'),
                      ),
                    ],
                  ),
                ),
              ),

            if (_wifiStatus == 'Permission Denied') const SizedBox(height: 16),

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
                      _wifiStatus == 'Connected' ? Colors.green : Colors.grey,
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
