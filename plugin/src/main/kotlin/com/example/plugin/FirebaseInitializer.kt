package com.example.plugin.utils

import com.google.auth.oauth2.GoogleCredentials
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import java.io.FileInputStream

object FirebaseInitializer {
    private var initialized = false

    fun initFirebase() {
        if (!initialized) {
            val serviceAccount = FileInputStream("plugin/src/main/resources/serviceAccountKey.json")

            val options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .build()

            FirebaseApp.initializeApp(options)
            initialized = true
        }
    }
}
