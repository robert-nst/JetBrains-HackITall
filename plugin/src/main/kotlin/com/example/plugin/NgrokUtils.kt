package com.example.plugin.utils

import com.example.plugin.EmbeddedServerHttp.log
import com.example.plugin.models.NgrokResponse
import com.google.gson.Gson
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

fun buildNgrokCommand(port: Int): List<String> {
    val ngrokExecutable = System.getenv("NGROK_PATH") ?: "ngrok"
    return if (System.getProperty("os.name").lowercase().contains("win")) {
        listOf("cmd", "/c", ngrokExecutable, "http", "localhost:$port")
    } else {
        listOf(ngrokExecutable, "http", "localhost:$port")
    }
}

fun runNgrokOutputReader(process: Process, timeoutSeconds: Long): String? {
    val executor = Executors.newSingleThreadExecutor()
    val future = executor.submit(Callable {
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val pattern = Regex("""Forwarding\s+(https?://\S+)""")
        val startTime = System.currentTimeMillis()
        while (System.currentTimeMillis() - startTime < timeoutSeconds * 1000) {
            while (reader.ready()) {
                val line = reader.readLine() ?: break
                log("ngrok output: $line")
                val matchResult = pattern.find(line)
                if (matchResult != null) {
                    val url = matchResult.groupValues[1]
                    log("Found URL in output: $url")
                    return@Callable url
                }
            }
            Thread.sleep(200)
        }
        log("Timeout reached while waiting for ngrok public URL.")
        null
    })
    return try {
        future.get(timeoutSeconds, TimeUnit.SECONDS)
    } catch (e: Exception) {
        log("Exception in ngrok output reader: ${e.message}")
        null
    } finally {
        executor.shutdown()
    }
}

fun getNgrokPublicUrlFromApi(): String? {
    val apiUrl = "http://localhost:4040/api/tunnels"
    val gson = Gson()
    return try {
        val url = URL(apiUrl)
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        val response = connection.inputStream.bufferedReader().use { it.readText() }
        connection.disconnect()
        log("ngrok API response: $response")
        val ngrokResponse = gson.fromJson(response, NgrokResponse::class.java)
        val tunnel = ngrokResponse.tunnels.firstOrNull { it.proto.equals("https", ignoreCase = true) }
            ?: ngrokResponse.tunnels.firstOrNull()
        tunnel?.publicUrl
    } catch (ex: Exception) {
        log("Error querying ngrok API: ${ex.message}")
        null
    }
}