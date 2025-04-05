package com.example.plugin

data class GetFixRequest(
    val buildMessage: String
)

data class FileFix(
    val filePath: String,
    val fixedCode: String
)

data class GetFixResponse(
    val success: Boolean,
    val files: List<FileFix>,
    val error: String? = null
)
