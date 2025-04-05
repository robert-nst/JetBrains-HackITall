//package com.example.plugin
//
//import com.intellij.openapi.project.Project
//import com.intellij.openapi.vfs.VirtualFile
//import com.google.gson.Gson
//
///**
// * Recursively reads all files in the given project's base directory
// * and returns a list of maps containing the file paths and their contents.
// */
//fun readProjectFiles(project: Project): List<Map<String, String>> {
//    val filesData = mutableListOf<Map<String, String>>()
//    val baseDir: VirtualFile = project.baseDir ?: return filesData
//
//    fun traverse(file: VirtualFile) {
//        if (file.isDirectory) {
//            file.children.forEach { traverse(it) }
//        } else {
//            // Read the file contents as a String
//            val content = String(file.contentsToByteArray())
//            filesData.add(mapOf("path" to file.path, "content" to content))
//        }
//    }
//    traverse(baseDir)
//    return filesData
//}
//
///**
// * Converts the list of file data to a JSON string using Gson.
// */
//fun convertFilesToJson(filesData: List<Map<String, String>>): String {
//    return Gson().toJson(filesData)
//}
