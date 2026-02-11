import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class FtpService {
  static const MethodChannel _channel = MethodChannel('com.eaaaarl.earlftp/ftp');

  // Get WiFi Information
  Future<Map<String, dynamic>> getWifiInformation() async {
      final permissionStatus = await Permission.location.request();
      if (!permissionStatus.isGranted) {
        print("Location permission denied");
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
      print("Failed to get WiFi information: ${e.message}");
      return {
        'wifiStatus': 'Disconnected',
        'ipAddress': 'N/A',
        'networkName': 'N/A',
      };
    }
  }
  Future<bool> hasLocationPermission() async {
    return await Permission.location.isGranted;
  }
}