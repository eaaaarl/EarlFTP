package com.eaaaarl.earlftp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
class MainActivity : FlutterActivity() {

    private val channel = "com.eaaaarl.earlftp/ftp"
    private val wifiHandler by lazy { WifiHandler(applicationContext) }
    private val ftpHandler by lazy { FtpHandler() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getWifiInformation" -> result.success(wifiHandler.getWifiInformation())
                    "startFtpServer" -> result.success(
                        ftpHandler.start(
                            username = call.argument("username") ?: "admin",
                            password = call.argument("password") ?: "admin123",
                            rootPath = call.argument("rootPath") ?: "/storage/emulated/0/",
                            anonymousAccess = call.argument("anonymousAccess") ?: false
                        )
                    )
                    "stopFtpServer" -> result.success(mapOf("success" to ftpHandler.stop()))
                    "getServerStatus" -> result.success(ftpHandler.getStatus())
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        ftpHandler.stop()
    }
}