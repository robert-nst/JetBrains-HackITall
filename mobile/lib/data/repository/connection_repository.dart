import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:mobile/utils/app_constants.dart';

class ConnectionRepository {
  Future<bool> ping(String baseUrl) async {
    
    final url = Uri.parse('$baseUrl/status');
    logger.d('Sending request to: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      logger.d('Ping response status code: ${response.statusCode}');
      return response.statusCode == 200;
    } on TimeoutException {
      logger.e('Ping request timed out');
      return false;
    } catch (e) {
      logger.e('Error pinging URL: $e');
      return false;
    }
  }
}
