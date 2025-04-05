import 'package:http/http.dart' as http;
import 'package:mobile/utils/app_constants.dart';

class ConnectionRepository {
  Future<bool> ping(String baseUrl) async {
    final url = Uri.parse('$baseUrl/status');
    logger.d('Pinging URL: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      logger.d('Ping response status code: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      logger.e('Error pinging URL: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getStatus(String baseUrl) async {
    final url = Uri.parse('$baseUrl/status');
    final response = await http.get(url).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.body as Map);
    } else {
      throw Exception('Failed to get status');
    }
  }
}
