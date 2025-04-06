import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/utils/app_constants.dart';

class BuildRepository {

  Future<Map<String, dynamic>> runBuild(String baseUrl) async {

    final url = Uri.parse('$baseUrl/runApplication');
    logger.d('Sending request to: $url');

    try {
      final response = await http.post(url).timeout(const Duration(seconds: 5));
      logger.d('Run application response status code: ${response.statusCode}');

      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } on TimeoutException {
      logger.e('Run application request timed out');
      return {
        "success": false,
        "message": "Request timed out. Please try again."
      };
    } catch (e) {
      logger.e('Error running application: $e');
      return {
        "success": false,
        "message": "An error occurred: $e"
      };
    }
  }

  Future<Map<String, dynamic>?> getBuildStatus(String baseUrl) async {
    final url = Uri.parse('$baseUrl/getBuildStatus');
    logger.d('Polling build status at: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      logger.d('Build status response status code: ${response.statusCode}');

      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } on TimeoutException {
      logger.e('Build status request timed out');
      return null;
    } catch (e) {
      logger.e('Error getting build status: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> requestFix(String baseUrl) async {
    final url = Uri.parse('$baseUrl/getFix');
    logger.d('Sending fix request to: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      logger.d('Fix response status: ${response.statusCode}');
      
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } on TimeoutException {
      logger.e('AI fix request timed out');
      return null;
    } catch (e) {
      logger.e('AI fix request error: $e');
      return null;
    }
  }
}
