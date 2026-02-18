import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ftp_service.dart';
import '../../features/home/widgets/permission_banner.dart';
import '../../features/home/widgets/network_status_card.dart';
import '../../features/home/widgets/server_details_card.dart';
import '../../features/home/widgets/server_actions_button.dart';

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
  int _serverPort = 0;
  final String _userId = 'admin';
  final String _password = 'admin123';
  bool _anonymousAccess = false;
  final String _rootFolder = '/storage/emulated/0/';
  bool _hasLocationPermission = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    _hasLocationPermission = await _ftpService.hasLocationPermission();

    if (_hasLocationPermission) {
      _loadWifiInformation();
    } else {
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

  Future<void> _showStoragePermissionDialog() async {
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_open, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Storage Permission',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
        content: const Text(
          'To access and share files via FTP, we need storage permission. '
              'This allows you to browse and transfer files.',
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
      final granted = await _ftpService.requestAllPermissions();
      if (!granted) {
        _showSnackBar('Storage permission denied', Colors.red);
      }
    }
  }

  Future<void> _loadWifiInformation() async {
    final wifiInfo = await _ftpService.getWifiInformation();

    setState(() {
      _wifiStatus = wifiInfo['wifiStatus'] ?? 'Unknown';
      _ipAddress = wifiInfo['ipAddress'] ?? 'N/A';
      _networkName = wifiInfo['networkName'] ?? 'N/A';
      _hasLocationPermission = wifiInfo['wifiStatus'] != 'Permission Denied';
    });
  }

  Future<void> _toggleServer() async {
    // Check permission before starting server
    if (!_isServerRunning && _wifiStatus == 'Permission Denied') {
      _showPermissionExplanationDialog();
      return;
    }

    if (!_isServerRunning) {
      final hasStorage = await _ftpService.hasStoragePermission();
      if (!hasStorage) {
        await _showStoragePermissionDialog();
        // Check again after dialog
        final stillNoPermission = !await _ftpService.hasStoragePermission();
        if (stillNoPermission) {
          return; // Don't start server without storage permission
        }
      }
    }
    setState(() {
      _isLoading = true;
    });

    if (_isServerRunning) {
      // Stop server
      final stopped = await _ftpService.stopFtpServer();
      setState(() {
        _isServerRunning = false;
        _serverPort = 0;
        _serverUrl = '';
        _isLoading = false;
      });

      if (stopped) {
        _showSnackBar('FTP Server stopped', Colors.orange);
      }
    } else {
      // Start server
      final result = await _ftpService.startFtpServer(
        username: _userId,
        password: _password,
        rootPath: _rootFolder,
        anonymousAccess: _anonymousAccess,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        setState(() {
          _isServerRunning = true;
          _serverPort = result['port'] ?? 0;
          _serverUrl = 'ftp://$_ipAddress:$_serverPort';
        });
        _showSnackBar(
          'FTP Server started on port $_serverPort',
          Colors.green,
        );
      } else {
        _showSnackBar(
          result['message'] ?? 'Failed to start server',
          Colors.red,
        );
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied to clipboard', Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi FTP Server'),
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
            if (_wifiStatus == 'Permission Denied')
              PermissionBanner(onGrant: _checkPermissionAndLoad),
            const SizedBox(height: 16),
            NetworkStatusCard(
              wifiStatus: _wifiStatus,
              ipAddress: _ipAddress,
              networkName: _networkName,
            ),
            // Start/Stop Server Button
            const SizedBox(height: 24),

            ServerActionButton(
              isRunning: _isServerRunning,
              isLoading: _isLoading,
              onPressed: _toggleServer,
            ),

            // Server Details (shown only when server is running)
            if (_isServerRunning) ...[
              const SizedBox(height: 24),
              ServerDetailsCard(
                url: _serverUrl,
                port: _serverPort,
                userId: _userId,
                password: _password,
                rootFolder: _rootFolder,
                anonymousAccess: _anonymousAccess,
                onCopy: _copyToClipboard,
                onAnonymousChanged: (val) => setState(() => _anonymousAccess = val),
              ),
            ],
          ],
        ),
      ),
    );
  }
}