package com.example.testhack

import com.google.zxing.BarcodeFormat
import com.google.zxing.common.BitMatrix
import com.google.zxing.qrcode.QRCodeWriter
import java.awt.image.BufferedImage

object QRCodeGenerator {
    @Throws(Exception::class)
    fun generateQRCodeImage(text: String, width: Int, height: Int): BufferedImage {
        val qrCodeWriter = QRCodeWriter()
        val bitMatrix: BitMatrix = qrCodeWriter.encode(text, BarcodeFormat.QR_CODE, width, height)
        val image = BufferedImage(width, height, BufferedImage.TYPE_INT_RGB)
        for (x in 0 until width) {
            for (y in 0 until height) {
                val color = if (bitMatrix.get(x, y)) 0x000000 else 0xFFFFFF
                image.setRGB(x, y, color)
            }
        }
        return image
    }
}
