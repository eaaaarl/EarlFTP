package com.eaaaarl.earlftp

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.apache.ftpserver.FtpServer
import org.apache.ftpserver.FtpServerFactory
import org.apache.ftpserver.ftplet.Authority
import org.apache.ftpserver.ftplet.UserManager
import org.apache.ftpserver.listener.ListenerFactory
import org.apache.ftpserver.usermanager.PropertiesUserManagerFactory
import org.apache.ftpserver.usermanager.impl.BaseUser
import org.apache.ftpserver.usermanager.impl.WritePermission
import java.io.File
import java.net.InetAddress
import java.net.NetworkInterface
import java.net.ServerSocket

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.eaaaarl.earlftp/ftp"
    private var ftpServer: FtpServer? = null
    private var currentPort: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWifiInformation" -> {
                    val wifiData = getWifiInformation()
                    result.success(wifiData)
                }
                "startFtpServer" -> {
                    val username = call.argument<String>("username") ?: "admin"
                    val password = call.argument<String>("password") ?: "admin123"
                    val rootPath = call.argument<String>("rootPath") ?: "/storage/emulated/0/"
                    val anonymousAccess = call.argument<Boolean>("anonymousAccess") ?: false

                    val serverData = startFtpServer(username, password, rootPath, anonymousAccess)
                    result.success(serverData)
                }
                "stopFtpServer" -> {
                    val stopped = stopFtpServer()
                    result.success(mapOf("success" to stopped))
                }
                "getServerStatus" -> {
                    val isRunning = ftpServer?.isStopped == false
                    result.success(mapOf(
                        "isRunning" to isRunning,
                        "port" to currentPort
                    ))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getWifiInformation(): Map<String, String> {
        // Check location permissions
        val fineLocationGranted = ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val coarseLocationGranted = ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (!fineLocationGranted && !coarseLocationGranted) {
            return mapOf(
                "wifiStatus" to "Permission Denied",
                "networkName" to "N/A",
                "ipAddress" to "N/A"
            )
        }

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
            ssid.replace("\"", "").takeIf { it != "<unknown ssid>" } ?: "N/A"
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

    private fun findAvailablePort(): Int {
        return try {
            ServerSocket(0).use { socket ->
                socket.localPort
            }
        } catch (e: Exception) {
            e.printStackTrace()
            2121 // Fallback to default FTP port
        }
    }

    private fun startFtpServer(
        username: String,
        password: String,
        rootPath: String,
        anonymousAccess: Boolean
    ): Map<String, Any> {
        return try {
            // Stop existing server if running
            stopFtpServer()

            // Find available port
            currentPort = findAvailablePort()

            val serverFactory = FtpServerFactory()

            // Configure listener
            val listenerFactory = ListenerFactory()
            listenerFactory.port = currentPort

            serverFactory.addListener("default", listenerFactory.createListener())

            // Configure user manager
            val userManagerFactory = PropertiesUserManagerFactory()
            val userManager: UserManager = userManagerFactory.createUserManager()

            // Create user
            val user = BaseUser()
            user.name = username
            user.password = password
            user.homeDirectory = rootPath

            val authorities = mutableListOf<Authority>()
            authorities.add(WritePermission())
            user.authorities = authorities

            userManager.save(user)

            // Add anonymous user if enabled
            if (anonymousAccess) {
                val anonymousUser = BaseUser()
                anonymousUser.name = "anonymous"
                anonymousUser.password = ""
                anonymousUser.homeDirectory = rootPath
                anonymousUser.authorities = authorities
                userManager.save(anonymousUser)
            }

            serverFactory.userManager = userManager

            // Start server
            ftpServer = serverFactory.createServer()
            ftpServer?.start()

            mapOf(
                "success" to true,
                "port" to currentPort,
                "message" to "FTP Server started on port $currentPort"
            )
        } catch (e: Exception) {
            e.printStackTrace()
            mapOf(
                "success" to false,
                "port" to 0,
                "message" to "Failed to start server: ${e.message}"
            )
        }
    }

    private fun stopFtpServer(): Boolean {
        return try {
            ftpServer?.stop()
            ftpServer = null
            currentPort = 0
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopFtpServer()
    }
}