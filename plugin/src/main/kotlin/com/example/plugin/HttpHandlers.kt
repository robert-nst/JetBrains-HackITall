package com.example.plugin.handlers

import com.example.plugin.EmbeddedServerHttp
import com.example.plugin.EmbeddedServerHttp.BuildStatus
import com.example.plugin.OpenAIClient
import com.example.plugin.models.*
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
                                            EmbeddedServerHttp.log("[APP] ${event.text}")
                                        }

                                        override fun processTerminated(event: ProcessEvent) {
                                            val status = if (event.exitCode == 0) BuildStatus.SUCCESS else BuildStatus.FAILURE
                                            EmbeddedServerHttp.currentBuildStatus = status
                                            EmbeddedServerHttp.log("[APP] Process terminated with exit code: ${event.exitCode}")
                                        }
                                    })
                                } else {
                                    EmbeddedServerHttp.currentBuildStatus = BuildStatus.FAILURE
                                    EmbeddedServerHttp.log("[APP] Failed to obtain process handler.")
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
            if (exchange.requestMethod.equals("GET", ignoreCase = true)) {
                val gson = Gson()
                val json = gson.toJson(
                    mapOf(
                        "status" to EmbeddedServerHttp.currentBuildStatus.name.lowercase(),
                        "logs" to EmbeddedServerHttp.getLastLogs()
                    )
                )
                val responseBytes = json.toByteArray(StandardCharsets.UTF_8)
                exchange.responseHeaders.add("Content-Type", "application/json")
                exchange.sendResponseHeaders(200, responseBytes.size.toLong())
                exchange.responseBody.write(responseBytes)
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

class GetFixHandler : HttpHandler {
    override fun handle(exchange: HttpExchange) {
        try {
            if (exchange.requestMethod.equals("POST", ignoreCase = true)) {
                val gson = Gson()
                val requestBody = exchange.requestBody.bufferedReader().readText()
                val getFixRequest = gson.fromJson(requestBody, GetFixRequest::class.java)

                val buildMessage = getFixRequest.buildMessage
                if (buildMessage.isBlank()) {
                    respond(exchange, GetFixResponse(false, emptyList(), "Build message is missing"))
                    return
                }

                val project = EmbeddedServerHttp.currentProject ?: run {
                    respond(exchange, GetFixResponse(false, emptyList(), "No project available"))
                    return
                }

                val sourceFiles = mutableMapOf<String, String>()
                val base = File(project.basePath!!)
                base.walkTopDown().filter { it.isFile && it.extension in listOf("java", "kt") }
                    .forEach { sourceFiles[it.relativeTo(base).path] = it.readText() }

                val files = OpenAIClient.getFixesFromOpenAI(buildMessage, sourceFiles)
                respond(exchange, com.example.plugin.GetFixResponse(true, files))
            } else {
                exchange.sendResponseHeaders(405, -1)
            }
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