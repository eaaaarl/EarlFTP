import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class FtpService {
  static const MethodChannel _channel = MethodChannel('com.eaaaarl.earlftp/ftp');

  // Request all necessary permissions
  Future<bool> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    // If manage external storage is not granted, check if storage is granted
    if (!allGranted && statuses[Permission.storage]!.isGranted) {
      allGranted = true;
    }

    return allGranted;
  }

  // Get WiFi Information
  Future<Map<String, dynamic>> getWifiInformation() async {
    // Request location permission first
    final permissionStatus = await Permission.location.request();

    if (!permissionStatus.isGranted) {
      debugPrint("Location permission denied");
      return {
        'wifiStatus': 'Permission Denied',
        'ipAddress': 'N/A',
        'networkName': 'N/A',
        'error': 'Location permission is required to access WiFi information',
      };
    }

    try {
      final result = await _channel.invokeMethod('getWifiInformation');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint("Failed to get WiFi information: ${e.message}");
      return {
        'wifiStatus': 'Disconnected',
        'ipAddress': 'N/A',
        'networkName': 'N/A',
      };
    }
  }

  // Start FTP Server with storage permission check
  Future<Map<String, dynamic>> startFtpServer({
    required String username,
    required String password,
    required String rootPath,
    required bool anonymousAccess,
  }) async {
    // Request storage permissions before starting server
    final hasStoragePermission = await requestAllPermissions();

    if (!hasStoragePermission) {
      return {
        'success': false,
        'port': 0,
        'message': 'Storage permission is required to access files',
      };
    }

    try {
      final result = await _channel.invokeMethod('startFtpServer', {
        'username': username,
        'password': password,
        'rootPath': rootPath,
        'anonymousAccess': anonymousAccess,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint("Failed to start FTP server: ${e.message}");
      return {
        'success': false,
        'port': 0,
        'message': 'Failed to start server: ${e.message}',
      };
    }
  }

  // Stop FTP Server
  Future<bool> stopFtpServer() async {
    try {
      final result = await _channel.invokeMethod('stopFtpServer');
      return result['success'] ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to stop FTP server: ${e.message}");
      return false;
    }
  }

  // Get Server Status
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final result = await _channel.invokeMethod('getServerStatus');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint("Failed to get server status: ${e.message}");
      return {
        'isRunning': false,
        'port': 0,
      };
    }
  }

  // Check if permission is already granted
  Future<bool> hasLocationPermission() async {
    return await Permission.location.isGranted;
  }

  // Check storage permissions
  Future<bool> hasStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    return await Permission.storage.isGranted;
  }
}