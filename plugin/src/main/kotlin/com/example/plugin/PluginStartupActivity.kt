package com.example.plugin

import com.intellij.openapi.project.Project
import com.intellij.openapi.startup.ProjectActivity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class PluginStartupActivity : ProjectActivity {
    override suspend fun execute(project: Project) {
        // Set the current project so the run endpoint can work.
        EmbeddedServerHttp.currentProject = project
        // Start the HTTP server (on a background thread).
        withContext(Dispatchers.IO) {
            EmbeddedServerHttp.start()
        }
    }
}
