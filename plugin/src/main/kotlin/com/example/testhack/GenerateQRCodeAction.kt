package com.example.testhack

import com.google.gson.Gson
import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import java.net.HttpURLConnection
import java.net.URL
import javax.imageio.ImageIO
import javax.swing.ImageIcon
import javax.swing.JOptionPane
import java.util.Base64
import java.io.ByteArrayInputStream

data class GenerateQRResponse(val connectionId: String, val qrCode: String)

class GenerateQRCodeAction : AnAction("Generate QR Code") {
    override fun actionPerformed(e: AnActionEvent) {
        try {
            val url = URL("http://localhost:4567/generateQR")
            with(url.openConnection() as HttpURLConnection) {
                requestMethod = "GET"
                inputStream.bufferedReader().use { reader ->
                    val response = reader.readText()
                    println("Response: $response")
                    val responseData = Gson().fromJson(response, GenerateQRResponse::class.java)
                    val imageBytes = Base64.getDecoder().decode(responseData.qrCode)
                    val image = ImageIO.read(ByteArrayInputStream(imageBytes))
                    JOptionPane.showMessageDialog(
                        null,
                        null,
                        "QR Code (Session ID: ${responseData.connectionId})",
                        JOptionPane.INFORMATION_MESSAGE,
                        ImageIcon(image)
                    )
                }
            }
        } catch (ex: Exception) {
            ex.printStackTrace()
            JOptionPane.showMessageDialog(null, "Error: ${ex.message}", "Error", JOptionPane.ERROR_MESSAGE)
        }
    }
}
