package com.example.plugin

import com.intellij.ide.ui.laf.darcula.DarculaUIUtil
import com.intellij.openapi.project.Project
import com.intellij.openapi.wm.ToolWindow
import com.intellij.openapi.wm.ToolWindowFactory
import com.intellij.ui.JBColor
import com.intellij.ui.components.JBLabel
import com.intellij.ui.components.JBTextField
import com.intellij.ui.content.ContentFactory
import com.intellij.ui.components.JBScrollPane
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
        // Define colors: Running in green and Starting... in yellow.
        private val STATUS_RUNNING = JBColor(Color(76, 175, 80), Color(76, 175, 80))
        private val STATUS_STARTING = JBColor(Color(255, 235, 59), Color(255, 235, 59))
        private val BACKGROUND_CARD = JBColor(Color(245, 245, 245), Color(50, 50, 50))
    }

    override fun createToolWindowContent(project: Project, toolWindow: ToolWindow) {
        // Define a common width for both the URL and QR panels.
        val commonWidth = JBUI.scale(400)

        // Main panel using vertical BoxLayout.
        val rootPanel = JPanel().apply {
            layout = BoxLayout(this, BoxLayout.Y_AXIS)
            border = JBUI.Borders.empty(16)
            background = UIUtil.getPanelBackground()
        }

        // --- Welcome Panel (separate) ---
        val welcomePanel = JPanel().apply {
            layout = BoxLayout(this, BoxLayout.Y_AXIS)
            alignmentX = Component.CENTER_ALIGNMENT
            isOpaque = false
        }
        val welcomeLabel = JBLabel("Welcome, and we are glad you use our plugin.").apply {
            font = UIUtil.getLabelFont().deriveFont(Font.PLAIN, JBUI.scaleFontSize(14f).toFloat())
        }
        welcomePanel.add(welcomeLabel)
        welcomePanel.maximumSize = welcomePanel.preferredSize

        // --- Header Panel (Title and Status) ---
        val headerPanel = JPanel().apply {
            layout = BoxLayout(this, BoxLayout.Y_AXIS)
            alignmentX = Component.CENTER_ALIGNMENT
            isOpaque = false
        }
        val titleLabel = JBLabel("Tunnel").apply {
            font = UIUtil.getLabelFont().deriveFont(Font.BOLD, JBUI.scaleFontSize(16f).toFloat())
            border = JBUI.Borders.emptyBottom(4)
        }
        val statusLabel = JBLabel("Status: Unknown").apply {
            font = UIUtil.getLabelFont().deriveFont(Font.PLAIN, JBUI.scaleFontSize(12f).toFloat())
            border = JBUI.Borders.emptyBottom(4)
        }
        headerPanel.add(titleLabel)
        headerPanel.add(statusLabel)
        headerPanel.maximumSize = headerPanel.preferredSize

        // --- Public URL Card Panel ---
        val urlCardPanel = JPanel(BorderLayout()).apply {
            alignmentX = Component.CENTER_ALIGNMENT
            border = BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(JBColor.border(), 1, true),
                JBUI.Borders.empty(16)
            )
            background = BACKGROUND_CARD
            maximumSize = Dimension(commonWidth, JBUI.scale(120))
        }
        val urlLabel = JBLabel("Public URL").apply {
            font = UIUtil.getLabelFont().deriveFont(Font.BOLD)
            border = JBUI.Borders.emptyBottom(8)
        }
        val urlField = JBTextField().apply {
            isEditable = false
            border = CompoundBorder(
                BorderFactory.createLineBorder(JBColor.border(), 1, true),
                JBUI.Borders.empty(8, 12)
            )
            font = UIUtil.getLabelFont()
        }
        val buttonPanel = JPanel(FlowLayout(FlowLayout.LEFT, JBUI.scale(8), 0)).apply {
            background = BACKGROUND_CARD
            border = JBUI.Borders.emptyTop(12)
        }
        val copyButton = JButton("Copy URL").apply {
            putClientProperty(DarculaUIUtil.COMPACT_PROPERTY, true)
        }
        val qrButton = JButton("Hide QR").apply {
            putClientProperty(DarculaUIUtil.COMPACT_PROPERTY, true)
        }
        val refreshButton = JButton("Refresh Now").apply {
            putClientProperty(DarculaUIUtil.COMPACT_PROPERTY, true)
        }
        buttonPanel.add(copyButton)
        buttonPanel.add(qrButton)
        buttonPanel.add(refreshButton)
        urlCardPanel.add(urlLabel, BorderLayout.NORTH)
        urlCardPanel.add(urlField, BorderLayout.CENTER)
        urlCardPanel.add(buttonPanel, BorderLayout.SOUTH)
        urlCardPanel.maximumSize = urlCardPanel.preferredSize

        // --- Group Info Panel (Header and Public URL together) ---
        val infoPanel = JPanel().apply {
            layout = BoxLayout(this, BoxLayout.Y_AXIS)
            alignmentX = Component.CENTER_ALIGNMENT
            isOpaque = false
        }
        infoPanel.add(headerPanel)
        infoPanel.add(Box.createRigidArea(Dimension(0, 10))) // slight gap between header and URL panel
        infoPanel.add(urlCardPanel)
        infoPanel.maximumSize = infoPanel.preferredSize

        // --- QR Code Panel ---
        val qrPanel = JPanel(BorderLayout()).apply {
            alignmentX = Component.CENTER_ALIGNMENT
            border = JBUI.Borders.empty(16, 0)
            background = UIUtil.getPanelBackground()
            maximumSize = Dimension(commonWidth, JBUI.scale(400))
        }
        val qrImagePanel = JPanel(GridBagLayout()).apply {
            border = BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(JBColor.border(), 1, true),
                JBUI.Borders.empty(16)
            )
            background = Color.WHITE
        }
        val qrImageLabel = JLabel("QR code not available", SwingConstants.CENTER).apply {
            horizontalAlignment = SwingConstants.CENTER
        }
        qrImagePanel.add(qrImageLabel)
        qrPanel.add(qrImagePanel, BorderLayout.CENTER)
        // Instruction label with HTML wrapping to force text to wrap.
        val instructionLabel = JBLabel(
            "<html><div style='width:200px; text-align:center;'>" +
                    "To connect to the workspace, scan the QR code in the mobile app or enter the public URL manually." +
                    "</div></html>"
        ).apply {
            font = UIUtil.getLabelFont().deriveFont(Font.PLAIN, JBUI.scaleFontSize(12f).toFloat())
            border = JBUI.Borders.emptyTop(8)
            horizontalAlignment = SwingConstants.CENTER
        }
        qrPanel.add(instructionLabel, BorderLayout.SOUTH)
        qrPanel.maximumSize = qrPanel.preferredSize

        var qrVisible = true

        // Utility function to update QR code.
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

        // Refresh UI: update status and public URL.
        fun refreshUI() {
            val url = EmbeddedServerHttp.sessionPublicUrl
            val isRunning = url.isNotBlank()
            statusLabel.text = if (isRunning) {
                "<html>Status: <span style='color:#4CAF50;'>Running</span></html>"
            } else {
                "<html>Status: <span style='color:#FFEB3B;'>Starting...</span></html>"
            }
            urlField.text = if (isRunning) url else "Not Available"
            if (qrVisible) {
                updateQRCode()
                qrPanel.isVisible = true
            } else {
                qrPanel.isVisible = false
            }
        }

        // Button actions.
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

        // --- About Panel integrated below the QR section ---
        val aboutPanel = JPanel().apply {
            layout = BoxLayout(this, BoxLayout.Y_AXIS)
            alignmentX = Component.CENTER_ALIGNMENT
            isOpaque = false
        }
        val aboutLabel = JBLabel(
            "<html>" +
                    "<h2>About Tunnel Plugin</h2>" +
                    "<p>The plugin helps you build remotely an app so that you can be ready from anywhere.</p>" +
                    "<p>Developed by 1337.</p>" +
                    "<p>Thank you!</p>" +
                    "</html>"
        ).apply {
            font = UIUtil.getLabelFont()
        }
        aboutPanel.add(aboutLabel)
        // Set the about panel to a fixed width of 200px.
        val fixedWidth = JBUI.scale(200)
        aboutPanel.preferredSize = Dimension(fixedWidth, aboutPanel.preferredSize.height)
        aboutPanel.maximumSize = Dimension(fixedWidth, aboutPanel.preferredSize.height)

        // --- Assemble the UI ---
        // 1. Add welcome panel at the top.
        rootPanel.add(welcomePanel)
        rootPanel.add(Box.createRigidArea(Dimension(0, 20)))
        // 2. Add the info panel (header + public URL) below.
        rootPanel.add(infoPanel)
        rootPanel.add(Box.createRigidArea(Dimension(0, 10)))
        // 3. Add the QR panel.
        rootPanel.add(qrPanel)
        // 4. Add spacing, a horizontal separator, and then the about panel.
        rootPanel.add(Box.createRigidArea(Dimension(0, 20)))
        rootPanel.add(JSeparator(SwingConstants.HORIZONTAL))
        rootPanel.add(Box.createRigidArea(Dimension(0, 10)))
        rootPanel.add(aboutPanel)
        rootPanel.add(Box.createVerticalGlue())

        // Initial UI refresh.
        refreshUI()

        // Wrap the root panel in a scroll pane.
        val scrollPane = JBScrollPane(
            rootPanel,
            ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED,
            ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED
        )

        // Set up periodic refresh.
        val refreshTimer = fixedRateTimer(name = "UI-Refresher", daemon = true, period = 5000L) {
            SwingUtilities.invokeLater { refreshUI() }
        }
        toolWindow.addContentManagerListener(object : com.intellij.ui.content.ContentManagerListener {
            override fun contentRemoved(event: com.intellij.ui.content.ContentManagerEvent) {
                refreshTimer.cancel()
            }
        })

        val contentFactory = ContentFactory.SERVICE.getInstance()
        val contentMain = contentFactory.createContent(scrollPane, "Plugin Info", false)
        toolWindow.contentManager.addContent(contentMain)
    }
}
