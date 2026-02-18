package com.eaaaarl.earlftp

import org.apache.ftpserver.FtpServer
import org.apache.ftpserver.FtpServerFactory
import org.apache.ftpserver.ftplet.Authority
import org.apache.ftpserver.listener.ListenerFactory
import org.apache.ftpserver.usermanager.PropertiesUserManagerFactory
import org.apache.ftpserver.usermanager.impl.BaseUser
import org.apache.ftpserver.usermanager.impl.WritePermission
import java.net.ServerSocket

class FtpHandler {

    private var ftpServer: FtpServer? = null
    private var currentPort: Int = 0

    val isRunning: Boolean get() = ftpServer?.isStopped == false

    fun start(
        username: String,
        password: String,
        rootPath: String,
        anonymousAccess: Boolean
    ): Map<String, Any> {
        return try {
            stop()
            currentPort = findAvailablePort()

            val serverFactory = FtpServerFactory()
            serverFactory.addListener("default", ListenerFactory().apply {
                port = currentPort
            }.createListener())

            val userManager = PropertiesUserManagerFactory().createUserManager()
            val authorities = mutableListOf<Authority>(WritePermission())

            userManager.save(BaseUser().apply {
                name = username
                this.password = password
                homeDirectory = rootPath
                this.authorities = authorities
            })

            if (anonymousAccess) {
                userManager.save(BaseUser().apply {
                    name = "anonymous"
                    this.password = ""
                    homeDirectory = rootPath
                    this.authorities = authorities
                })
            }

            serverFactory.userManager = userManager
            ftpServer = serverFactory.createServer()
            ftpServer?.start()

            mapOf("success" to true, "port" to currentPort, "message" to "FTP Server started on port $currentPort")
        } catch (e: Exception) {
            mapOf("success" to false, "port" to 0, "message" to "Failed to start: ${e.message}")
        }
    }

    fun stop(): Boolean {
        return try {
            ftpServer?.stop()
            ftpServer = null
            currentPort = 0
            true
        } catch (e: Exception) {
            false
        }
    }

    fun getStatus(): Map<String, Any> {
        return mapOf("isRunning" to isRunning, "port" to currentPort)
    }

    private fun findAvailablePort(): Int {
        return try {
            ServerSocket(0).use { it.localPort }
        } catch (e: Exception) {
            2121
        }
    }
}