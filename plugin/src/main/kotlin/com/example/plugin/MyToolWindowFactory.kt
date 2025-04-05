package com.example.plugin

import com.intellij.ide.ui.laf.darcula.DarculaUIUtil
import com.intellij.openapi.project.Project
import com.intellij.openapi.wm.ToolWindow
import com.intellij.openapi.wm.ToolWindowFactory
import com.intellij.ui.JBColor
import com.intellij.ui.components.JBLabel
import com.intellij.ui.components.JBScrollPane
import com.intellij.ui.components.JBTextField
import com.intellij.ui.content.ContentFactory
import com.intellij.util.ui.JBUI
import com.intellij.util.ui.UIUtil
import java.awt.*
import java.awt.datatransfer.StringSelection
import java.awt.image.BufferedImage
import java.io.ByteArrayInputStream
import java.util.*
import javax.imageio.ImageIO
import javax.swing.*
import javax.swing.border.CompoundBorder
import kotlin.concurrent.fixedRateTimer

class MyToolWindowFactory : ToolWindowFactory {

    companion object {
        private val STATUS_RUNNING = JBColor(Color(76, 175, 80), Color(76, 175, 80))
        private val STATUS_STOPPED = JBColor(Color(244, 67, 54), Color(244, 67, 54))
        private val BACKGROUND_CARD = JBColor(Color(245, 245, 245), Color(50, 50, 50))
    }

    override fun createToolWindowContent(project: Project, toolWindow: ToolWindow) {
        val rootPanel = JPanel()
        rootPanel.layout = BoxLayout(rootPanel, BoxLayout.Y_AXIS)
        rootPanel.border = JBUI.Borders.empty(16)

        // === 1. Header with Simplified Server Status ===
        val headerPanel = JPanel()
        headerPanel.layout = BoxLayout(headerPanel, BoxLayout.Y_AXIS)
        headerPanel.alignmentX = Component.LEFT_ALIGNMENT
        headerPanel.border = JBUI.Borders.emptyBottom(16)

        val titleLabel = JBLabel("LocalShare")
        titleLabel.font = UIUtil.getLabelFont()
            .deriveFont(Font.BOLD)
            .deriveFont(JBUI.scaleFontSize(16f))
        titleLabel.border = JBUI.Borders.emptyBottom(4)

        val statusLabel = JBLabel("Status: Unknown")
        statusLabel.font = UIUtil.getLabelFont()
            .deriveFont(JBUI.scaleFontSize(12f))
        statusLabel.border = JBUI.Borders.emptyBottom(4)

        headerPanel.add(titleLabel)
        headerPanel.add(statusLabel)

        // === 2. URL Card Panel ===
        val urlCardPanel = JPanel(BorderLayout())
        urlCardPanel.alignmentX = Component.LEFT_ALIGNMENT
        urlCardPanel.border = BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(JBColor.border(), 1, true),
            JBUI.Borders.empty(16)
        )
        urlCardPanel.background = BACKGROUND_CARD

        val urlLabel = JBLabel("Public URL")
        urlLabel.font = UIUtil.getLabelFont().deriveFont(Font.BOLD)
        urlLabel.border = JBUI.Borders.emptyBottom(8)

        val urlField = JBTextField()
        urlField.isEditable = false
        urlField.border = CompoundBorder(
            BorderFactory.createLineBorder(JBColor.border(), 1, true),
            JBUI.Borders.empty(8, 12)
        )
        urlField.font = UIUtil.getLabelFont()

        val buttonPanel = JPanel(FlowLayout(FlowLayout.LEFT, JBUI.scale(8), 0))
        buttonPanel.background = BACKGROUND_CARD
        buttonPanel.border = JBUI.Borders.emptyTop(12)

        val copyButton = JButton("Copy URL")
        copyButton.putClientProperty(DarculaUIUtil.COMPACT_PROPERTY, true)

        val qrButton = JButton("Hide QR")
        qrButton.putClientProperty(DarculaUIUtil.COMPACT_PROPERTY, true)

        val refreshButton = JButton("Refresh Now")
        refreshButton.putClientProperty(DarculaUIUtil.COMPACT_PROPERTY, true)

        buttonPanel.add(copyButton)
        buttonPanel.add(qrButton)
        buttonPanel.add(refreshButton)

        urlCardPanel.add(urlLabel, BorderLayout.NORTH)
        urlCardPanel.add(urlField, BorderLayout.CENTER)
        urlCardPanel.add(buttonPanel, BorderLayout.SOUTH)

        // === 3. QR Code Panel ===
        val qrPanel = JPanel(BorderLayout())
        qrPanel.alignmentX = Component.LEFT_ALIGNMENT
        qrPanel.border = JBUI.Borders.empty(16, 0)

        val qrImagePanel = JPanel(GridBagLayout())
        qrImagePanel.border = BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(JBColor.border(), 1, true),
            JBUI.Borders.empty(16)
        )
        qrImagePanel.background = Color.WHITE

        val qrImageLabel = JLabel("QR code not available", SwingConstants.CENTER)
        qrImageLabel.horizontalAlignment = SwingConstants.CENTER
        qrImagePanel.add(qrImageLabel)

        qrPanel.add(qrImagePanel, BorderLayout.CENTER)

        var qrVisible = true

        // === 4. Logs Panel ===
        val logsPanel = JPanel(BorderLayout())
        logsPanel.alignmentX = Component.LEFT_ALIGNMENT
        logsPanel.border = JBUI.Borders.empty(16, 0, 0, 0)

        val logsHeaderPanel = JPanel(BorderLayout())
        logsHeaderPanel.border = JBUI.Borders.emptyBottom(8)
        logsHeaderPanel.isOpaque = false

        val logsLabel = JBLabel("Recent Activity")
        logsLabel.font = UIUtil.getLabelFont().deriveFont(Font.BOLD)
        logsHeaderPanel.add(logsLabel, BorderLayout.WEST)

        val logsArea = JTextArea()
        logsArea.isEditable = false
        logsArea.lineWrap = true
        logsArea.wrapStyleWord = true
        logsArea.font = Font("Monospaced", Font.PLAIN, JBUI.scaleFontSize(12f).toInt())
        logsArea.border = JBUI.Borders.empty(8)

        val logsScroll = JBScrollPane(logsArea)
        logsScroll.border = BorderFactory.createLineBorder(JBColor.border(), 1, true)
        logsScroll.preferredSize = Dimension(JBUI.scale(400), JBUI.scale(200))

        logsPanel.add(logsHeaderPanel, BorderLayout.NORTH)
        logsPanel.add(logsScroll, BorderLayout.CENTER)

        // === 5. Utility Functions ===
        fun updateQRCode() {
            try {
                val base64 = EmbeddedServerHttp.sessionQrCode
                if (base64.isNotBlank()) {
                    val bytes = Base64.getDecoder().decode(base64)
                    val image: BufferedImage = ImageIO.read(ByteArrayInputStream(bytes))
                    qrImageLabel.icon = ImageIcon(image)
                    qrImageLabel.text = null
                } else {
                    qrImageLabel.icon = null
                    qrImageLabel.text = "QR code not available"
                }
            } catch (e: Exception) {
                qrImageLabel.icon = null
                qrImageLabel.text = "QR code not available"
            }
        }

        fun refreshUI() {
            val url = EmbeddedServerHttp.sessionPublicUrl
            val isRunning = url.isNotBlank()

            // Status update
            statusLabel.text = if (isRunning) {
                "<html>Status: <span style='color:#4CAF50;'>Running</span></html>"
            } else {
                "<html>Status: <span style='color:#F44336;'>Stopped</span></html>"
            }

            urlField.text = if (isRunning) url else "Not Available"
            urlField.isEnabled = isRunning
            logsArea.text = EmbeddedServerHttp.getLastLogs()

            if (qrVisible) {
                updateQRCode()
                qrPanel.isVisible = true
            } else {
                qrPanel.isVisible = false
            }
        }

        // === 6. Button Actions ===
        copyButton.addActionListener {
            val text = urlField.text
            if (text.isNotBlank() && text != "Not Available") {
                val clipboard = Toolkit.getDefaultToolkit().systemClipboard
                clipboard.setContents(StringSelection(text), null)
            }
        }

        qrButton.addActionListener {
            qrVisible = !qrVisible
            qrPanel.isVisible = qrVisible
            qrButton.text = if (qrVisible) "Hide QR" else "Show QR"
            if (qrVisible) updateQRCode()
        }

        refreshButton.addActionListener {
            refreshUI()
        }

        // === 7. Add Components ===
        rootPanel.add(headerPanel)
        rootPanel.add(urlCardPanel)
        rootPanel.add(qrPanel)
        rootPanel.add(logsPanel)

        // === 8. Initial Refresh ===
        refreshUI()

        // === 9. Periodic Auto Refresh ===
        val refreshTimer = fixedRateTimer(name = "UI-Refresher", daemon = true, period = 5000L) {
            SwingUtilities.invokeLater { refreshUI() }
        }

        toolWindow.addContentManagerListener(object : com.intellij.ui.content.ContentManagerListener {
            override fun contentRemoved(event: com.intellij.ui.content.ContentManagerEvent) {
                refreshTimer.cancel()
            }
        })

        val contentFactory = ContentFactory.SERVICE.getInstance()
        val content = contentFactory.createContent(rootPanel, "", false)
        toolWindow.contentManager.addContent(content)
    }
}
