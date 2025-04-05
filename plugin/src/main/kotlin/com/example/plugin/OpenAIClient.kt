package com.example.plugin

import org.json.JSONObject
import java.io.BufferedReader
import java.io.OutputStream
import java.net.HttpURLConnection
import java.net.URL

object OpenAIClient {
    private const val OPENAI_API_KEY = "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" // Replace with your key
    private const val MODEL = "gpt-4" // Or "gpt-3.5-turbo"

    fun getFixedCode(buildMessage: String): String {
        val prompt = """
            The following Java project build failed. Analyze the logs and return the corrected version of the codebase. 
            Only return the full fixed source code. No extra explanations, no extra formatting, no extra output, no extra information before or after writing the code, just the code itself.

            Build Log:
            $buildMessage
        """.trimIndent()

        val payload = JSONObject()
        payload.put("model", MODEL)
        payload.put("messages", listOf(
            mapOf("role" to "system", "content" to "You're an expert in debugging Java applications."),
            mapOf("role" to "user", "content" to prompt)
        ))
        payload.put("temperature", 0.2)

        val url = URL("https://api.openai.com/v1/chat/completions")
        val connection = url.openConnection() as HttpURLConnection

        connection.requestMethod = "POST"
        connection.setRequestProperty("Content-Type", "application/json")
        connection.setRequestProperty("Authorization", "Bearer $OPENAI_API_KEY")
        connection.doOutput = true

        val outputStream: OutputStream = connection.outputStream
        outputStream.write(payload.toString().toByteArray(Charsets.UTF_8))
        outputStream.flush()
        outputStream.close()

        val response = StringBuilder()
        val reader = BufferedReader(connection.inputStream.reader())
        reader.useLines { lines -> lines.forEach { response.append(it) } }

        val jsonResponse = JSONObject(response.toString())
        return jsonResponse
            .getJSONArray("choices")
            .getJSONObject(0)
            .getJSONObject("message")
            .getString("content")
            .trim()
    }

    fun getFixesFromOpenAI(buildMessage: String, codebase: Map<String, String>): List<FileFix> {
        val filesJson = codebase.entries.joinToString("\n") { "\"${it.key}\": \"\"\"${it.value}\"\"\"" }
        val userPrompt = """
        The Java project failed to build. Here's the error log and source code.
        Fix the errors and return ONLY JSON with this structure:
        {
            "files": [
                {"filePath": "path/to/File.java", "fixedCode": "full fixed content"},
                ...
            ]
        }

        Build Error Log:
        $buildMessage

        Files:
        {
            $filesJson
        }
    """.trimIndent()

        val payload = JSONObject()
        payload.put("model", MODEL)
        payload.put("messages", listOf(
            mapOf("role" to "system", "content" to "You're a helpful Java debugging assistant."),
            mapOf("role" to "user", "content" to userPrompt)
        ))
        payload.put("temperature", 0.3)

        val url = URL("https://api.openai.com/v1/chat/completions")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.setRequestProperty("Content-Type", "application/json")
        connection.setRequestProperty("Authorization", "Bearer $OPENAI_API_KEY")
        connection.doOutput = true

        connection.outputStream.use { it.write(payload.toString().toByteArray()) }

        val response = connection.inputStream.bufferedReader().readText()
        val jsonResponse = JSONObject(response)
        val message = jsonResponse
            .getJSONArray("choices")
            .getJSONObject(0)
            .getJSONObject("message")
            .getString("content")

        // Parse JSON from message
        val parsed = JSONObject(message)
        val filesArray = parsed.getJSONArray("files")

        return (0 until filesArray.length()).map { i ->
            val obj = filesArray.getJSONObject(i)
            FileFix(
                filePath = obj.getString("filePath"),
                fixedCode = obj.getString("fixedCode")
            )
        }
    }

}
