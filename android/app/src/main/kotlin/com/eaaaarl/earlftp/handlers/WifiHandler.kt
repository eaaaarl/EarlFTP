package com.eaaaarl.earlftp

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import androidx.core.content.ContextCompat
import java.net.InetAddress
import java.net.NetworkInterface

class WifiHandler(private val context: Context) {

    fun getWifiInformation(): Map<String, String> {
        if (!hasLocationPermission()) {
            return mapOf(
                "wifiStatus" to "Permission Denied",
                "networkName" to "N/A",
                "ipAddress" to "N/A"
            )
        }

        val wifiStatus = getWifiStatus()
        val networkName = if (wifiStatus == "Connected") getNetworkName() else "N/A"
        val ipAddress = if (wifiStatus == "Connected") getIPAddress() ?: "N/A" else "N/A"

        return mapOf(
            "wifiStatus" to wifiStatus,
            "networkName" to networkName,
            "ipAddress" to ipAddress
        )
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun getWifiStatus(): String {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val capabilities = cm.getNetworkCapabilities(cm.activeNetwork)
            if (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true) "Connected" else "Disconnected"
        } else {
            @Suppress("DEPRECATION")
            val info = cm.activeNetworkInfo
            @Suppress("DEPRECATION")
            if (info?.type == ConnectivityManager.TYPE_WIFI && info.isConnected) "Connected" else "Disconnected"
        }
    }

    private fun getNetworkName(): String {
        val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val ssid = wifiManager.connectionInfo.ssid
        return ssid.replace("\"", "").takeIf { it != "<unknown ssid>" } ?: "N/A"
    }

    private fun getIPAddress(): String? {
        return try {
            NetworkInterface.getNetworkInterfaces()
                .asSequence()
                .flatMap { it.inetAddresses.asSequence() }
                .firstOrNull {
                    !it.isLoopbackAddress &&
                            it is InetAddress &&
                            it.hostAddress?.indexOf(':') == -1
                }?.hostAddress
        } catch (e: Exception) {
            null
        }
    }
}