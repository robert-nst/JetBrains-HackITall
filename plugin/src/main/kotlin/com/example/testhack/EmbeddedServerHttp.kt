package com.example.testhack

import com.google.gson.Gson
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
import java.net.InetSocketAddress
import java.nio.charset.StandardCharsets
import java.util.*
import javax.imageio.ImageIO
import java.util.Base64

data class RunRequest(val connectionId: String)
data class RunResponse(val success: Boolean, val message: String)
// New data class for status response.
data class StatusResponse(val status: String)

object EmbeddedServerHttp {
    var currentProject: com.intellij.openapi.project.Project? = null
    // Generate these once at startup.
    var sessionConnectionId: String = ""
    var sessionQrCode: String = ""

    // New variable to track the application status.
    // Initially, we can consider it "not running" until the server starts.
    var applicationStatus: String = "not running"

    private var server: HttpServer? = null

    fun start() {
        try {
            sessionConnectionId = UUID.randomUUID().toString()
            sessionQrCode = try {
                val qrImage: BufferedImage = QRCodeGenerator.generateQRCodeImage(sessionConnectionId, 200, 200)
                imageToBase64(qrImage)
            } catch (ex: Exception) {
                ex.printStackTrace()
                ""
            }
            println("Session connection ID: $sessionConnectionId")
            server = HttpServer.create(InetSocketAddress(4567), 0)
            println("HTTP server created on port 4567")
            server?.createContext("/generateQR", GenerateQRHandler())
            server?.createContext("/runApplication", RunApplicationHandler())
            // Register the new /status endpoint.
            server?.createContext("/status", StatusHandler())
            server?.executor = null
            server?.start()
            println("HTTP server started on port 4567")
            // When the server starts, if no run is in progress, update status to "running".
            if (!applicationStatus.equals("in progress", ignoreCase = true)) {
                applicationStatus = "running"
            }
        } catch (ex: Exception) {
            ex.printStackTrace()
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
                    if (runRequest.connectionId == sessionConnectionId) {
                        val project = currentProject
                        if (project != null) {
                            val runManager = RunManager.getInstance(project)
                            val configurationSettings = runManager.selectedConfiguration
                            if (configurationSettings != null) {
                                val executor = DefaultRunExecutor.getRunExecutorInstance()
                                val environment = ExecutionEnvironmentBuilder.create(executor, configurationSettings).build()
                                // Set status to "in progress" before launching.
                                applicationStatus = "in progress"
                                ApplicationManager.getApplication().invokeLater {
                                    ExecutionManager.getInstance(project).restartRunProfile(environment)
                                    // Once the run starts, update the status to "running".
                                    applicationStatus = "running"
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

    // New StatusHandler endpoint.
    private class StatusHandler : HttpHandler {
        override fun handle(exchange: HttpExchange) {
            try {
                if (exchange.requestMethod.equals("GET", ignoreCase = true)) {
                    // Determine status based on applicationStatus and whether the server is running.
                    val status: String = if (applicationStatus.equals("in progress", ignoreCase = true)) {
                        "in progress"
                    } else if (server != null) {
                        "running"
                    } else {
                        "not running"
                    }
                    // Map the status to an HTTP response code.
                    val httpStatusCode = when (status.lowercase()) {
                        "running" -> 200
                        "in progress" -> 202
                        "not running" -> 503
                        else -> 500
                    }
                    val jsonResponse = Gson().toJson(StatusResponse(status))
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
        val bytes = baos.toByteArray()
        return Base64.getEncoder().encodeToString(bytes)
    }
}
