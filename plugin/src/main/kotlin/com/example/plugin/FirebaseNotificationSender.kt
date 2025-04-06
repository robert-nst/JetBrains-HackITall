package com.example.plugin

import com.google.auth.oauth2.GoogleCredentials
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import org.json.JSONObject
import java.io.FileInputStream
import java.io.IOException
import resources.*

object FirebaseNotificationSender {

    private const val FCM_URL =
        "https://fcm.googleapis.com/v1/projects/jetbrains-hackitall/messages:send"
    private const val SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
    private val client = OkHttpClient()

    private fun getAccessToken(): String {
        val serviceAccountStream = FileInputStream("C:\\Users\\alexn\\Desktop\\JetBrains-HackITall\\plugin\\src\\main\\resources\\serviceAccountKey.json")
        val googleCredentials = GoogleCredentials
            .fromStream(serviceAccountStream)
            .createScoped(listOf(SCOPE))
        googleCredentials.refreshIfExpired()
        return googleCredentials.accessToken.tokenValue
    }

    fun sendNotification(title: String, body: String, deviceToken: String) {
        val messageJson = JSONObject().apply {
            put("message", JSONObject().apply {
                put("token", deviceToken)
                put("notification", JSONObject().apply {
                    put("title", title)
                    put("body", body)
                })
            })
        }

        val requestBody = RequestBody.create(
            "application/json; charset=utf-8".toMediaType(),
            messageJson.toString()
        )

        val request = Request.Builder()
            .url(FCM_URL)
            .post(requestBody)
            .addHeader("Authorization", "Bearer ${getAccessToken()}")
            .addHeader("Content-Type", "application/json; charset=utf-8")
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                println("❌ Failed to send notification: ${e.message}")
            }

            override fun onResponse(call: Call, response: Response) {
                val respBody = response.body?.string()
                println("✅ Notification sent successfully: $respBody")
                response.close()
            }
        })
    }
}
