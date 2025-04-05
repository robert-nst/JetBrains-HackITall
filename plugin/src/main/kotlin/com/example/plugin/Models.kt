package com.example.plugin.models

import com.google.gson.annotations.SerializedName

// Used by /runApplication
data class RunRequest(
    val connectionId: String
)

data class RunResponse(
    val success: Boolean,
    val message: String
)

// Used by /getFix

data class GetFixRequest(
    val buildMessage: String
)

data class GetFixResponse(
    val success: Boolean,
    val files: List<Pair<String, String>>,
    val message: String? = null
)

// Used by Ngrok API parsing

data class NgrokTunnel(
    @SerializedName("public_url") val publicUrl: String,
    @SerializedName("proto") val proto: String
)

data class NgrokResponse(
    val tunnels: List<NgrokTunnel>
)