package com.example.plugin

import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import com.intellij.execution.RunManager
import com.intellij.execution.executors.DefaultRunExecutor
import com.intellij.execution.runners.ExecutionEnvironmentBuilder
import com.intellij.execution.ExecutionManager
import com.intellij.openapi.application.ApplicationManager
import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpHandler
import com.sun.net.httpserver.HttpServer
import java.awt.image.BufferedImage
import java.io.ByteArrayOutputStream
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.InetSocketAddress
import java.net.URI
import java.net.URL
import java.nio.charset.StandardCharsets
import java.util.*
import javax.imageio.ImageIO
import java.util.Base64
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

// Data classes for JSON requests/responses.
data class RunRequest(val connectionId: String)
data class RunResponse(val success: Boolean, val message: String)

object EmbeddedServerHttp {
    // Set from the startup activity.
    var currentProject: com.intellij.openapi.project.Project? = null

    // Public URL from ngrok and the extracted unique connection ID.
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

    fun getLastLogs(): String {
        return logs.joinToString("\n")
    }

    fun start() {
        try {
            // Use environment variable NGROK_PORT if set; otherwise, default to 4567.
            val port = System.getenv("NGROK_PORT")?.toIntOrNull() ?: 4567

            // Start the HTTP server.
            server = HttpServer.create(InetSocketAddress(port), 0)
            println("HTTP server created on port $port")
            log("HTTP server created on port $port")
            server?.createContext("/generateQR", GenerateQRHandler())
            server?.createContext("/runApplication", RunApplicationHandler())
            server?.createContext("/buildStatus", BuildStatusHandler())
            // New /status endpoint for plugin status.
            server?.createContext("/status", StatusHandler())
            server?.executor = null
            server?.start()
            println("HTTP server started on port $port")
            log("HTTP server started on port $port")

            // Launch ngrok.
            val ngrokExecutable = System.getenv("NGROK_PATH") ?: "ngrok"
            // On Windows, run via "cmd /c"
            val commandList = if (System.getProperty("os.name").lowercase().contains("win")) {
                listOf("cmd", "/c", ngrokExecutable, "http", "localhost:$port")
            } else {
                listOf(ngrokExecutable, "http", "localhost:$port")
            }
            println("Starting ngrok tunnel with command: ${commandList.joinToString(" ")}")
            log("Starting ngrok tunnel with command: ${commandList.joinToString(" ")}")
            ngrokProcess = ProcessBuilder(commandList)
                .redirectErrorStream(true)
                .start()

            // Read ngrok output (with a 10-second timeout) to get a public URL.
            val urlFromOutput = runNgrokOutputReader(ngrokProcess!!, timeoutSeconds = 10)
            sessionPublicUrl = if (!urlFromOutput.isNullOrEmpty()) {
                println("Using ngrok public URL from output: $urlFromOutput")
                log("Using ngrok public URL from output: $urlFromOutput")
                urlFromOutput
            } else {
                println("No public URL found in ngrok output; querying ngrok API...")
                log("No public URL found in ngrok output; querying ngrok API...")
                val apiUrl = getNgrokPublicUrlFromApi()
                if (!apiUrl.isNullOrEmpty()) {
                    println("Found ngrok tunnel via API: $apiUrl")
                    log("Found ngrok tunnel via API: $apiUrl")
                    apiUrl
                } else {
                    println("Falling back to localhost.")
                    log("Falling back to localhost.")
                    "http://localhost:$port"
                }
            }

            // Extract the unique connection ID from the public URL.
            sessionConnectionId = try {
                val uri = URI(sessionPublicUrl)
                // Extract the subdomain (before the first period)
                uri.host.substringBefore(".")
            } catch (ex: Exception) {
                ex.printStackTrace()
                UUID.randomUUID().toString()
            }
            println("Session connection ID set to: $sessionConnectionId")
            log("Session connection ID set to: $sessionConnectionId")
            println("Full ngrok public URL: $sessionPublicUrl")
            log("Full ngrok public URL: $sessionPublicUrl")

            // Generate the QR code using the full public URL.
            sessionQrCode = try {
                val qrImage: BufferedImage = QRCodeGenerator.generateQRCodeImage(sessionPublicUrl, 200, 200)
                imageToBase64(qrImage)
            } catch (ex: Exception) {
                ex.printStackTrace()
                ""
            }
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
    }

    fun stop() {
        try {
            server?.stop(0)
            println("HTTP server stopped.")
            log("HTTP server stopped.")
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
        try {
            ngrokProcess?.destroy()
            println("ngrok process terminated.")
            log("ngrok process terminated.")
        } catch (ex: Exception) {
            ex.printStackTrace()
        }
    }

    private fun runNgrokOutputReader(process: Process, timeoutSeconds: Long): String? {
        val executor = Executors.newSingleThreadExecutor()
        val future = executor.submit(Callable<String?> {
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val pattern = Regex("""Forwarding\s+(https?://\S+)""")
            val startTime = System.currentTimeMillis()
            while (System.currentTimeMillis() - startTime < timeoutSeconds * 1000) {
                while (reader.ready()) {
                    val line = reader.readLine() ?: break
                    println("ngrok output: $line")
                    log("ngrok output: $line")
                    val matchResult = pattern.find(line)
                    if (matchResult != null) {
                        val url = matchResult.groupValues[1]
                        println("Found URL in output: $url")
                        log("Found URL in output: $url")
                        return@Callable url
                    }
                }
                Thread.sleep(200)
            }
            println("Timeout reached while waiting for ngrok public URL.")
            log("Timeout reached while waiting for ngrok public URL.")
            null
        })
        return try {
            future.get(timeoutSeconds, TimeUnit.SECONDS)
        } catch (e: Exception) {
            println("Exception in ngrok output reader: ${e.message}")
            log("Exception in ngrok output reader: ${e.message}")
            null
        } finally {
            executor.shutdown()
        }
    }

    data class NgrokTunnel(
        @SerializedName("public_url") val publicUrl: String,
        @SerializedName("proto") val proto: String
    )

    data class NgrokResponse(
        val tunnels: List<NgrokTunnel>
    )

    private fun getNgrokPublicUrlFromApi(): String? {
        val apiUrl = "http://localhost:4040/api/tunnels"
        val gson = Gson()
        return try {
            val url = URL(apiUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            val response = connection.inputStream.bufferedReader().use { it.readText() }
            connection.disconnect()
            println("ngrok API response: $response")
            log("ngrok API response: $response")
            val ngrokResponse = gson.fromJson(response, NgrokResponse::class.java)
            // Prefer HTTPS tunnels.
            val tunnel = ngrokResponse.tunnels.firstOrNull { it.proto.equals("https", ignoreCase = true) }
                ?: ngrokResponse.tunnels.firstOrNull()
            tunnel?.publicUrl
        } catch (ex: Exception) {
            println("Error querying ngrok API: ${ex.message}")
            log("Error querying ngrok API: ${ex.message}")
            null
        }
    }

    private class GenerateQRHandler : HttpHandler {
        override fun handle(exchange: HttpExchange) {
            try {
                if (exchange.requestMethod.equals("GET", ignoreCase = true)) {
                    val jsonResponse = """{"connectionId": "$sessionConnectionId", "qrCode": "$sessionQrCode"}"""
                    val responseBytes = jsonResponse.toByteArray(StandardCharsets.UTF_8)
                    exchange.responseHeaders.add("Content-Type", "application/json")
                    exchange.sendResponseHeaders(200, responseBytes.size.toLong())
                    exchange.responseBody.write(responseBytes)
                    exchange.responseBody.close()
                } else {
                    exchange.sendResponseHeaders(405, -1)
                }
            } catch (ex: Exception) {
                ex.printStackTrace()
                exchange.sendResponseHeaders(500, -1)
            } finally {
                exchange.close()
            }
        }
    }

    private class RunApplicationHandler : HttpHandler {
        override fun handle(exchange: HttpExchange) {
            try {
                if (exchange.requestMethod.equals("POST", ignoreCase = true)) {
                    val requestBody = exchange.requestBody.bufferedReader().readText()
                    val gson = Gson()
                    val runRequest = gson.fromJson(requestBody, RunRequest::class.java)
                    println("Received run request with connectionId: ${runRequest.connectionId}")
                    log("Received run request with connectionId: ${runRequest.connectionId}")
                    // Compare the incoming connectionId with the unique ID extracted earlier.
                    if (runRequest.connectionId == sessionConnectionId) {
                        val project = currentProject
                        if (project != null) {
                            val runManager = RunManager.getInstance(project)
                            val configurationSettings = runManager.selectedConfiguration
                            if (configurationSettings != null) {
                                val executor = DefaultRunExecutor.getRunExecutorInstance()
                                val environment = ExecutionEnvironmentBuilder
                                    .create(executor, configurationSettings)
                                    .build()
                                // Update build status: set to RUNNING when starting.
                                currentBuildStatus = BuildStatus.RUNNING
                                ApplicationManager.getApplication().invokeLater {
                                    ExecutionManager.getInstance(project)
                                        .restartRunProfile(environment)
                                    // Optionally update build status based on run outcome.
                                }
                                val response = RunResponse(true, "Run configuration executed.")
                                val responseBytes = gson.toJson(response).toByteArray(StandardCharsets.UTF_8)
                                exchange.responseHeaders.add("Content-Type", "application/json")
                                exchange.sendResponseHeaders(200, responseBytes.size.toLong())
                                exchange.responseBody.write(responseBytes)
                            } else {
                                val response = RunResponse(false, "No run configuration selected.")
                                val responseBytes = gson.toJson(response).toByteArray(StandardCharsets.UTF_8)
                                exchange.responseHeaders.add("Content-Type", "application/json")
                                exchange.sendResponseHeaders(400, responseBytes.size.toLong())
                                exchange.responseBody.write(responseBytes)
                            }
                        } else {
                            val response = RunResponse(false, "No project available.")
                            val responseBytes = gson.toJson(response).toByteArray(StandardCharsets.UTF_8)
                            exchange.responseHeaders.add("Content-Type", "application/json")
                            exchange.sendResponseHeaders(400, responseBytes.size.toLong())
                            exchange.responseBody.write(responseBytes)
                        }
                    } else {
                        val response = RunResponse(false, "Invalid connection ID.")
                        val responseBytes = gson.toJson(response).toByteArray(StandardCharsets.UTF_8)
                        exchange.responseHeaders.add("Content-Type", "application/json")
                        exchange.sendResponseHeaders(403, responseBytes.size.toLong())
                        exchange.responseBody.write(responseBytes)
                    }
                } else {
                    exchange.sendResponseHeaders(405, -1)
                }
            } catch (ex: Exception) {
                ex.printStackTrace()
                exchange.sendResponseHeaders(500, -1)
            } finally {
                exchange.close()
            }
        }
    }

    // New /status endpoint (separate from /buildStatus).
    private class StatusHandler : HttpHandler {
        override fun handle(exchange: HttpExchange) {
            try {
                if (exchange.requestMethod.equals("GET", ignoreCase = true)) {
                    // Determine status based on whether a public URL has been set.
                    val status = if (sessionPublicUrl.isNotBlank()) "running" else "not running"
                    val httpStatusCode = if (status == "running") 200 else 503
                    val jsonResponse = Gson().toJson(mapOf("status" to status))
                    val responseBytes = jsonResponse.toByteArray(StandardCharsets.UTF_8)
                    exchange.responseHeaders.add("Content-Type", "application/json")
                    exchange.sendResponseHeaders(httpStatusCode, responseBytes.size.toLong())
                    exchange.responseBody.write(responseBytes)
                } else {
                    exchange.sendResponseHeaders(405, -1)
                }
            } catch (ex: Exception) {
                ex.printStackTrace()
                exchange.sendResponseHeaders(500, -1)
            } finally {
                exchange.close()
            }
        }
    }

    private fun imageToBase64(image: BufferedImage): String {
        val baos = ByteArrayOutputStream()
        ImageIO.write(image, "png", baos)
        return Base64.getEncoder().encodeToString(baos.toByteArray())
    }

    private class BuildStatusHandler : HttpHandler {
        override fun handle(exchange: HttpExchange) {
            try {
                if (exchange.requestMethod.equals("GET", ignoreCase = true)) {
                    val status = currentBuildStatus
                    val httpStatusCode = when (status) {
                        BuildStatus.RUNNING, BuildStatus.SUCCESS -> 200
                        BuildStatus.IDLE -> 503
                        BuildStatus.FAILURE -> 500
                    }
                    val jsonResponse = Gson().toJson(mapOf("status" to status.name.lowercase()))
                    val responseBytes = jsonResponse.toByteArray(StandardCharsets.UTF_8)
                    exchange.responseHeaders.add("Content-Type", "application/json")
                    exchange.sendResponseHeaders(httpStatusCode, responseBytes.size.toLong())
                    exchange.responseBody.write(responseBytes)
                } else {
                    exchange.sendResponseHeaders(405, -1)
                }
            } catch (ex: Exception) {
                ex.printStackTrace()
                exchange.sendResponseHeaders(500, -1)
            } finally {
                exchange.close()
            }
        }
    }
}
