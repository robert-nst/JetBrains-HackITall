package com.example.plugin.handlers

import com.example.plugin.EmbeddedServerHttp
import com.example.plugin.EmbeddedServerHttp.BuildStatus
import com.example.plugin.OpenAIClient
import com.example.plugin.models.*
import com.example.plugin.handlers.FirebaseNotificationSender
import com.google.gson.Gson
import com.intellij.execution.ExecutionManager
import com.intellij.execution.RunManager
import com.intellij.execution.executors.DefaultRunExecutor
import com.intellij.execution.process.ProcessAdapter
import com.intellij.execution.process.ProcessEvent
import com.intellij.execution.runners.ExecutionEnvironmentBuilder
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.util.Key
import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpHandler
import java.io.File
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets

class GenerateQRHandler : HttpHandler {
    override fun handle(exchange: HttpExchange) {
        try {
            if (exchange.requestMethod.equals("GET", ignoreCase = true)) {
                val jsonResponse = """{"qrCode": \"${EmbeddedServerHttp.sessionQrCode}\"}"""
                val responseBytes = jsonResponse.toByteArray(StandardCharsets.UTF_8)
                exchange.responseHeaders.add("Content-Type", "application/json")
                exchange.sendResponseHeaders(200, responseBytes.size.toLong())
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

class RunApplicationHandler : HttpHandler {
    override fun handle(exchange: HttpExchange) {
        try {
            if (exchange.requestMethod.equals("POST", ignoreCase = true)) {
                val project = EmbeddedServerHttp.currentProject
                if (project != null) {
                    val runManager = RunManager.getInstance(project)
                    val config = runManager.selectedConfiguration
                    if (config != null) {
                        val executor = DefaultRunExecutor.getRunExecutorInstance()
                        val env = ExecutionEnvironmentBuilder.create(executor, config).build()

                        ApplicationManager.getApplication().invokeLater {
                            EmbeddedServerHttp.currentBuildStatus = BuildStatus.RUNNING
                            env.runner.execute(env) { descriptor ->
                                val handler = descriptor.processHandler
                                if (handler != null) {
                                    handler.addProcessListener(object : ProcessAdapter() {
                                        override fun onTextAvailable(event: ProcessEvent, outputType: Key<*>) {
                                            val text = event.text
                                            EmbeddedServerHttp.log("[APP] $text")

                                            if (text.contains("Tomcat started on port", ignoreCase = true)) {
                                                EmbeddedServerHttp.currentBuildStatus = BuildStatus.SUCCESS

                                                // Sending success notification
                                                EmbeddedServerHttp.fcmDeviceToken?.let { token ->
                                                    FirebaseNotificationSender.sendNotification(
                                                        title = "✅ Build Success",
                                                        body = "Your application built successfully.",
                                                        deviceToken = token
                                                    )
                                                }
                                            }
                                        }

                                        override fun processTerminated(event: ProcessEvent) {
                                            val status = if (event.exitCode == 0)
                                                BuildStatus.SUCCESS
                                            else
                                                BuildStatus.FAILURE

                                            EmbeddedServerHttp.currentBuildStatus = status
                                            EmbeddedServerHttp.log("[APP] Process terminated with exit code: ${event.exitCode}")

                                            // Sending notification based on build status
                                            EmbeddedServerHttp.fcmDeviceToken?.let { token ->
                                                val (title, body) = when (status) {
                                                    BuildStatus.SUCCESS -> "✅ Build Success" to "Your application built successfully."
                                                    BuildStatus.FAILURE -> "❌ Build Failure" to "Your application failed to build. Check details."
                                                    else -> "Build Status" to "Build completed with status: $status"
                                                }

                                                FirebaseNotificationSender.sendNotification(
                                                    title = title,
                                                    body = body,
                                                    deviceToken = token
                                                )
                                            }
                                        }
                                    })
                                } else {
                                    EmbeddedServerHttp.currentBuildStatus = BuildStatus.FAILURE
                                    EmbeddedServerHttp.log("[APP] Failed to obtain process handler.")

                                    // Send notification about failure to start the build
                                    EmbeddedServerHttp.fcmDeviceToken?.let { token ->
                                        FirebaseNotificationSender.sendNotification(
                                            title = "❌ Build Error",
                                            body = "Could not start the build process.",
                                            deviceToken = token
                                        )
                                    }
                                }
                            }
                        }
                        respond(exchange, RunResponse(true, "Run configuration executed."))
                    } else {
                        respond(exchange, RunResponse(false, "No run configuration selected."), 400)
                    }
                } else {
                    respond(exchange, RunResponse(false, "No project available."), 400)
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

    private fun respond(exchange: HttpExchange, response: Any, code: Int = 200) {
        val json = Gson().toJson(response)
        val bytes = json.toByteArray()
        exchange.responseHeaders.add("Content-Type", "application/json")
        exchange.sendResponseHeaders(code, bytes.size.toLong())
        exchange.responseBody.use { it.write(bytes) }
    }
}

class GetStatusHandler : HttpHandler {
    override fun handle(exchange: HttpExchange) {
        try {
            if (!exchange.requestMethod.equals("GET", ignoreCase = true)) {
                exchange.sendResponseHeaders(405, -1)
                exchange.close()
                return
            }

            val status = EmbeddedServerHttp.currentBuildStatus.name.lowercase()
            val logs = EmbeddedServerHttp.getLastLogs()
            EmbeddedServerHttp.lastBuildMessage = logs
            val responseMap = mutableMapOf<String, Any>(
                "status" to status
            )

            if (status == "failure") {
                try {
                    val summary = OpenAIClient.summarizeErrorWithContext(logs)
                    val projectBasePath = EmbeddedServerHttp.currentProject?.basePath
                        ?: throw IllegalStateException("No project available")

                    // Normalize the path: if absolute, use as-is; if relative, resolve from base path.
                    val file = File(summary.file).let { f ->
                        if (f.isAbsolute) f else File(projectBasePath, summary.file)
                    }

                    // Include the absolute path in the response, regardless of file existence.
                    responseMap["absoluteFilePath"] = file.absolutePath

                    if (!file.exists()) {
                        throw IllegalStateException("File not found: ${file.path}")
                    }

                    val lines = file.readLines()
                    val errorLineIndex = summary.line - 1
                    val contextMap = mapOf(
                        "line" to summary.line,
                        "before" to lines.subList((errorLineIndex - 5).coerceAtLeast(0), errorLineIndex),
                        "error" to lines.getOrNull(errorLineIndex).orEmpty(),
                        "after" to lines.subList(errorLineIndex + 1, (errorLineIndex + 6).coerceAtMost(lines.size))
                    )

                    responseMap["errorMessage"] = summary.message
                    responseMap["errorCode"] = contextMap

                } catch (e: Exception) {
                    e.printStackTrace()
                    responseMap["errorMessage"] = "Could not extract error context: ${e.message}"
                    responseMap["errorCode"] = ""
                }
            }

            val json = Gson().toJson(responseMap)
            val responseBytes = json.toByteArray(StandardCharsets.UTF_8)
            exchange.responseHeaders.add("Content-Type", "application/json")
            exchange.sendResponseHeaders(200, responseBytes.size.toLong())
            exchange.responseBody.write(responseBytes)
        } catch (e: Exception) {
            e.printStackTrace()
            exchange.sendResponseHeaders(500, -1)
        } finally {
            exchange.close()
        }
    }
}

class GetFixHandler : HttpHandler {
    override fun handle(exchange: HttpExchange) {
        try {
            if (!exchange.requestMethod.equals("GET", ignoreCase = true)) {
                exchange.sendResponseHeaders(405, -1)
                return
            }

            val buildMessage = EmbeddedServerHttp.lastBuildMessage ?: run {
                respond(exchange, GetFixResponse(false, emptyList(), "No build message available"))
                return
            }

            val project = EmbeddedServerHttp.currentProject ?: run {
                respond(exchange, GetFixResponse(false, emptyList(), "No project available"))
                return
            }

            val sourceFiles = mutableMapOf<String, String>()
            val base = File(project.basePath!!)
            base.walkTopDown()
                .filter { it.isFile && it.extension in listOf("java", "kt") }
                .forEach { sourceFiles[it.relativeTo(base).path] = it.readText() }

            val files = OpenAIClient.getFixesFromOpenAI(buildMessage, sourceFiles)
            EmbeddedServerHttp.lastFixFiles = files
            respond(exchange, GetFixResponse(true, files))

        } catch (e: Exception) {
            e.printStackTrace()
            respond(exchange, GetFixResponse(false, emptyList(), e.message))
        } finally {
            exchange.close()
        }
    }

    private fun respond(exchange: HttpExchange, response: Any, code: Int = 200) {
        val json = Gson().toJson(response)
        val bytes = json.toByteArray()
        exchange.responseHeaders.add("Content-Type", "application/json")
        exchange.sendResponseHeaders(code, bytes.size.toLong())
        exchange.responseBody.use { it.write(bytes) }
    }
}

class DoFixHandler : HttpHandler {
    override fun handle(exchange: HttpExchange) {
        try {
            if (!exchange.requestMethod.equals("POST", ignoreCase = true)) {
                exchange.sendResponseHeaders(405, -1)
                return
            }

            val files = EmbeddedServerHttp.lastFixFiles
            println(files)
            if (files.isEmpty()) {
                respond(exchange, DoFixResponse(false, emptyList(), "No fix data available"))
                return
            }

            val project = EmbeddedServerHttp.currentProject ?: run {
                respond(exchange, DoFixResponse(false, emptyList(), "No project available"))
                return
            }

            val updatedFiles = mutableListOf<String>()

            files.forEach { fileFix ->
                try {
                    val file = File(fileFix.path)
                    if (!file.exists()) {
                        file.parentFile.mkdirs()
                        file.createNewFile()
                    }

                    val cleanedCode = fileFix.code
                        .replace("```java", "")
                        .replace("```kotlin", "")
                        .replace("```kt", "")
                        .replace("```", "")
                        .trim()

                    file.writeText(cleanedCode)
                    updatedFiles.add(file.absolutePath)
                } catch (e: Exception) {
                    respond(exchange, DoFixResponse(false, updatedFiles, "Error writing ${fileFix.path}: ${e.message}"))
                    return
                }
            }

            respond(exchange, DoFixResponse(true, updatedFiles))

        } catch (e: Exception) {
            e.printStackTrace()
            respond(exchange, DoFixResponse(false, emptyList(), "Exception: ${e.message}"))
        } finally {
            exchange.close()
        }
    }

    private fun respond(exchange: HttpExchange, response: DoFixResponse, code: Int = 200) {
        val json = Gson().toJson(response)
        val bytes = json.toByteArray(Charsets.UTF_8)
        exchange.responseHeaders.add("Content-Type", "application/json")
        exchange.sendResponseHeaders(code, bytes.size.toLong())
        exchange.responseBody.use { it.write(bytes) }
    }
}

class StatusHandler : HttpHandler {
    override fun handle(exchange: HttpExchange) {
        try {
            if (exchange.requestMethod.equals("GET", ignoreCase = true)) {
                exchange.sendResponseHeaders(200, -1)
            } else {
                exchange.sendResponseHeaders(405, -1)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            exchange.sendResponseHeaders(500, -1)
        } finally {
            exchange.close()
        }
    }
}

class UpdateFCMTokenHandler : HttpHandler {
    override fun handle(exchange: HttpExchange) {
        if (!exchange.requestMethod.equals("POST", ignoreCase = true)) {
            exchange.sendResponseHeaders(405, -1)
            exchange.close()
            return
        }

        try {
            val body = exchange.requestBody.bufferedReader(StandardCharsets.UTF_8).use { it.readText() }
            val gson = Gson()
            val request = gson.fromJson(body, FCMTokenRequest::class.java)

            if (request.token.isNotBlank()) {
                EmbeddedServerHttp.fcmDeviceToken = request.token
                val response = """{"success": true, "message": "FCM token updated successfully."}"""
                exchange.sendResponseHeaders(200, response.length.toLong())
                exchange.responseHeaders.add("Content-Type", "application/json")
                exchange.responseBody.write(response.toByteArray())
            } else {
                val response = """{"success": false, "message": "Invalid token."}"""
                exchange.sendResponseHeaders(400, response.length.toLong())
                exchange.responseHeaders.add("Content-Type", "application/json")
                exchange.responseBody.write(response.toByteArray())
            }
        } catch (ex: Exception) {
            ex.printStackTrace()
            exchange.sendResponseHeaders(500, -1)
        } finally {
            exchange.close()
        }
    }
}