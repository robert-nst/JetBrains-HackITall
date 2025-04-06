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

data class FileFix(
    val path: String,
    val code: String
)

data class GetFixResponse(
    val success: Boolean,
    val files: List<FileFix>,
    val error: String? = null
)

// Used by /doFix
data class DoFixRequest(
    val files: List<FileFix>
)

data class DoFixResponse(
    val success: Boolean,
    val updated: List<String> = emptyList(),
    val error: String? = null
)

// Used by Ngrok API parsing

data class NgrokTunnel(
    @SerializedName("public_url") val publicUrl: String,
    @SerializedName("proto") val proto: String
)

data class NgrokResponse(
    val tunnels: List<NgrokTunnel>
)

data class ErrorSummary(
    val message: String,
    val file: String,
    val line: Int
)