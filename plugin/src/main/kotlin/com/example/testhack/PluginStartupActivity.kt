package com.example.testhack

import com.intellij.openapi.project.Project
import com.intellij.openapi.startup.ProjectActivity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import com.intellij.openapi.application.ApplicationManager

class PluginStartupActivity : ProjectActivity {
    override suspend fun execute(project: Project) {
        EmbeddedServerHttp.currentProject = project
        withContext(Dispatchers.IO) {
            EmbeddedServerHttp.start()
        }
        // Once the server has started (and the session values generated),
        // update the tool window. We schedule it on the EDT.
        ApplicationManager.getApplication().invokeLater {
            MyToolWindowFactory.updateContent(
                EmbeddedServerHttp.sessionQrCode,
                EmbeddedServerHttp.sessionConnectionId
            )
        }
    }
}
