package com.example.testhack

import com.intellij.openapi.project.Project
import com.intellij.openapi.wm.ToolWindow
import com.intellij.openapi.wm.ToolWindowFactory
import com.intellij.ui.content.ContentFactory
import java.awt.BorderLayout
import java.awt.Dimension
import javax.swing.Box
import javax.swing.BoxLayout
import javax.swing.ImageIcon
import javax.swing.JPanel
import javax.swing.JTextField
import javax.swing.SwingUtilities
import javax.swing.JLabel
import java.io.ByteArrayInputStream
import java.util.Base64
import javax.imageio.ImageIO

class MyToolWindowFactory : ToolWindowFactory {
    companion object {
        // Label for displaying the QR code image.
        var qrCodeLabel: JLabel? = null
        // Text field for displaying the connection ID (selectable).
        var idField: JTextField? = null

        // Updates both the QR code image and the connection ID text.
        fun updateContent(qrBase64: String, connectionId: String) {
            SwingUtilities.invokeLater {
                try {
                    if (qrBase64.isNotEmpty()) {
                        val imageBytes = Base64.getDecoder().decode(qrBase64)
                        val image = ImageIO.read(ByteArrayInputStream(imageBytes))
                        qrCodeLabel?.icon = ImageIcon(image)
                        qrCodeLabel?.text = ""
                    } else {
                        qrCodeLabel?.text = "QR code not available"
                    }
                } catch (ex: Exception) {
                    ex.printStackTrace()
                    qrCodeLabel?.text = "Error loading QR code"
                }
                idField?.text = connectionId
            }
        }
    }

    override fun createToolWindowContent(project: Project, toolWindow: ToolWindow) {
        val panel = JPanel().apply {
            layout = BoxLayout(this, BoxLayout.Y_AXIS)
            border = javax.swing.BorderFactory.createEmptyBorder(10, 10, 10, 10)
        }

        qrCodeLabel = JLabel("QR Code will appear here").apply {
            alignmentX = JLabel.CENTER_ALIGNMENT
        }
        panel.add(qrCodeLabel)

        panel.add(Box.createRigidArea(Dimension(0, 10)))

        idField = JTextField("ID will appear here").apply {
            isEditable = false
            maximumSize = Dimension(Int.MAX_VALUE, preferredSize.height)
        }
        panel.add(idField)

        val contentFactory = ContentFactory.SERVICE.getInstance()
        val content = contentFactory.createContent(panel, "", false)
        toolWindow.contentManager.addContent(content)

        // Unconditionally update content with current session values
        updateContent(EmbeddedServerHttp.sessionQrCode, EmbeddedServerHttp.sessionConnectionId)
    }
}
