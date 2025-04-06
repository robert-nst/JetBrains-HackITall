package com.example.plugin

import com.google.auth.oauth2.GoogleCredentials
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import java.io.FileInputStream
import resources.*


object FirebaseInitializer {
    private var initialized = false

    fun initFirebase() {
        if (!initialized) {
            val serviceAccount = FileInputStream("C:\\Users\\alexn\\Desktop\\JetBrains-HackITall\\plugin\\src\\main\\resources\\serviceAccountKey.json")

            val options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .build()

            FirebaseApp.initializeApp(options)
            initialized = true
        }
    }
}
