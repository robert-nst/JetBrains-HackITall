package com.example.plugin

import com.example.plugin.handlers.*
import com.example.plugin.models.*
import com.example.plugin.utils.*
import com.google.gson.Gson
import com.intellij.openapi.project.Project
import com.sun.net.httpserver.HttpServer
import java.awt.image.BufferedImage
import java.io.ByteArrayOutputStream
import java.net.InetSocketAddress
import java.net.URI
import java.util.*
import javax.imageio.ImageIO
import java.util.Base64

object EmbeddedServerHttp {
    var currentProject: Project? = null
    var sessionPublicUrl: String = ""
    var sessionConnectionId: String = ""
    var sessionQrCode: String = ""
    private var server: HttpServer? = null
    private var ngrokProcess: Process? = null
    private val logs = LinkedList<String>()

    enum class BuildStatus {
        IDLE, RUNNING, SUCCESS, FAILURE
    }

    @Volatile
    var currentBuildStatus: BuildStatus = BuildStatus.IDLE

    fun log(msg: String) {
        println(msg)
        if (logs.size > 50) logs.removeFirst()
        logs.add("[${Date()}] $msg")
    }

    fun getLastLogs(): String = logs.joinToString("\n")

    fun start() {
        try {
            val port = System.getenv("NGROK_PORT")?.toIntOrNull() ?: 4567
            server = HttpServer.create(InetSocketAddress(port), 0)
            log("HTTP server created on port $port")

            server?.apply {
                createContext("/generateQR", GenerateQRHandler())
                createContext("/runApplication", RunApplicationHandler())
                createContext("/getFix", GetFixHandler())
                server?.createContext("/doFix", DoFixHandler())
                createContext("/getBuildStatus", GetStatusHandler())
                createContext("/status", StatusHandler())
                executor = null
                start()
            }

            log("HTTP server started on port $port")

            val commandList = buildNgrokCommand(port)
            log("Starting ngrok tunnel with command: ${commandList.joinToString(" ")}")

            ngrokProcess = ProcessBuilder(commandList).redirectErrorStream(true).start()

            val urlFromOutput = runNgrokOutputReader(ngrokProcess!!, timeoutSeconds = 10)
            sessionPublicUrl = urlFromOutput ?: getNgrokPublicUrlFromApi() ?: "http://localhost:$port"

            sessionConnectionId = try {
                URI(sessionPublicUrl).host.substringBefore(".")
            } catch (ex: Exception) {
                UUID.randomUUID().toString()
            }

            sessionQrCode = try {
                val qrImage: BufferedImage = QRCodeGenerator.generateQRCodeImage(sessionPublicUrl, 200, 200)
                imageToBase64(qrImage)
            } catch (ex: Exception) {
                ex.printStackTrace()
                ""
            }

            log("Session connection ID set to: $sessionConnectionId")
            log("Full ngrok public URL: $sessionPublicUrl")
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
    }

    fun stop() {
        try {
            server?.stop(0)
            log("HTTP server stopped.")
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
        try {
            ngrokProcess?.destroy()
            log("ngrok process terminated.")
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
    }

    private fun imageToBase64(image: BufferedImage): String {
        val baos = ByteArrayOutputStream()
        ImageIO.write(image, "png", baos)
        return Base64.getEncoder().encodeToString(baos.toByteArray())
    }
}
