package com.example.plugin

import com.example.plugin.models.ErrorSummary
import com.example.plugin.models.FileFix
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import org.json.JSONObject
import java.util.regex.Pattern

object OpenAIClient {
    private const val API_KEY = "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"  // 🔐 put your actual key here
    private const val API_URL = "https://api.openai.com/v1/chat/completions"

    fun getFixesFromOpenAI(buildMessage: String, sourceFiles: Map<String, String>): List<FileFix> {
        val prompt = """
            You're an expert Java developer. A Spring Boot project failed to build. Your job is to fix the code.
            Return only the full corrected content for each file that needs to be updated, no explanations.
            Each file must be in this format:
            
            -- START OF FILE: path/to/File.java
            <full fixed code>
            -- END OF FILE
            
            Build failure logs:
            $buildMessage
        """.trimIndent()

        val body = JSONObject()
        body.put("model", "gpt-4")
        body.put("messages", listOf(
            mapOf("role" to "system", "content" to "You are a code fixer."),
            mapOf("role" to "user", "content" to prompt)
        ))
        body.put("temperature", 0.3)

        val requestBody = RequestBody.create(
            "application/json".toMediaTypeOrNull(),
            body.toString()
        )

        val request = Request.Builder()
            .url(API_URL)
            .addHeader("Authorization", "Bearer $API_KEY")
            .post(requestBody)
            .build()

        val client = OkHttpClient()
        val response = client.newCall(request).execute()
        if (!response.isSuccessful) throw Exception("OpenAI call failed: ${response.code}")

        val responseBody = response.body?.string() ?: throw Exception("No response body")
        val json = JSONObject(responseBody)
        val text = json.getJSONArray("choices").getJSONObject(0).getJSONObject("message").getString("content")

        return parseFileFixes(text)
    }

    private fun parseFileFixes(response: String): List<FileFix> {
        val pattern = Pattern.compile("-- START OF FILE: (.*?)\\R(.*?)\\R-- END OF FILE", Pattern.DOTALL)
        val matcher = pattern.matcher(response)

        val files = mutableListOf<FileFix>()
        while (matcher.find()) {
            val path = matcher.group(1).trim()
            val code = matcher.group(2).trim()
            files.add(FileFix(path, code))
        }
        return files
    }

    fun summarizeErrorWithContext(buildLogs: String): ErrorSummary {
        val prompt = """
        A Java build has failed. Extract:
        - A one-line summary of the cause (start with "MESSAGE:")
        - The source file path where the error happened (start with "FILE:")
        - The line number where the error occurred (start with "LINE:")

        Example:
        MESSAGE: Missing semicolon in DemoServerApplication.java at line 12.
        FILE: src/main/java/com/hack/demoserver/DemoServerApplication.java
        LINE: 12

        Build logs:
        $buildLogs
    """.trimIndent()

        val body = JSONObject()
        body.put("model", "gpt-4")
        body.put("messages", listOf(mapOf("role" to "user", "content" to prompt)))
        body.put("temperature", 0.2)

        val requestBody = RequestBody.create(
            "application/json".toMediaType(),
            body.toString()
        )

        val request = Request.Builder()
            .url("https://api.openai.com/v1/chat/completions")
            .addHeader("Authorization", "Bearer $API_KEY")
            .post(requestBody)
            .build()

        val client = OkHttpClient()
        val response = client.newCall(request).execute()
        if (!response.isSuccessful) throw Exception("OpenAI call failed")

        val text = JSONObject(response.body?.string())
            .getJSONArray("choices")
            .getJSONObject(0)
            .getJSONObject("message")
            .getString("content")

        val message = Regex("(?i)MESSAGE:\\s*(.*)").find(text)?.groupValues?.get(1)?.trim() ?: "Build failed"
        val file = Regex("(?i)FILE:\\s*(.*)").find(text)?.groupValues?.get(1)?.trim() ?: ""
        val line = Regex("(?i)LINE:\\s*(\\d+)").find(text)?.groupValues?.get(1)?.toIntOrNull() ?: -1

        return ErrorSummary(message, file, line)
    }
}
