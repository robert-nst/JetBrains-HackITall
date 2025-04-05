import 'package:http/http.dart' as http;

class ConnectionRepository {
  Future<bool> ping(String baseUrl) async {
    final url = Uri.parse('$baseUrl/ping');
    final response = await http.get(url).timeout(const Duration(seconds: 3));
    return response.statusCode == 200;
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
