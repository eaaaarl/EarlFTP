package com.eaaaarl.earlftp

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.InetAddress
import java.net.NetworkInterface

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.eaaaarl.earlftp/ftp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWifiInformation" -> {
                    val wifiData = getWifiInformation()
                    result.success(wifiData)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getWifiInformation(): Map<String, String> {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val connectivityManager = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        val wifiStatus: String
        val networkName: String
        val ipAddress: String

        // Check WiFi connection status
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork
            val capabilities = connectivityManager.getNetworkCapabilities(network)

            wifiStatus = if (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true) {
                "Connected"
            } else {
                "Disconnected"
            }
        } else {
            @Suppress("DEPRECATION")
            val networkInfo = connectivityManager.activeNetworkInfo
            @Suppress("DEPRECATION")
            wifiStatus = if (networkInfo?.type == ConnectivityManager.TYPE_WIFI && networkInfo.isConnected) {
                "Connected"
            } else {
                "Disconnected"
            }
        }

        // Get WiFi network name (SSID)
        networkName = if (wifiStatus == "Connected") {
            val connectionInfo: WifiInfo = wifiManager.connectionInfo
            val ssid = connectionInfo.ssid
            ssid.replace("\"", "") // Remove quotes from SSID
        } else {
            "N/A"
        }

        // Get IP Address
        ipAddress = if (wifiStatus == "Connected") {
            getIPAddress() ?: "N/A"
        } else {
            "N/A"
        }

        return mapOf(
            "wifiStatus" to wifiStatus,
            "networkName" to networkName,
            "ipAddress" to ipAddress
        )
    }

    private fun getIPAddress(): String? {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses

                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()

                    // Check if it's IPv4 and not loopback
                    if (!address.isLoopbackAddress && address is InetAddress) {
                        val hostAddress = address.hostAddress

                        // Filter IPv4 addresses
                        if (hostAddress?.indexOf(':') == -1) {
                            return hostAddress
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
}