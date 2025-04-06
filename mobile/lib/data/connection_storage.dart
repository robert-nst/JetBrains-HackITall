import 'package:shared_preferences/shared_preferences.dart';

class ConnectionStorage {
  static const _keyConnectedUrl = 'connected_url';

  static Future<void> saveConnectedUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConnectedUrl, url);
  }

  static Future<void> clearConnectedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyConnectedUrl);
  }

  static Future<String?> getSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConnectedUrl);
  }
}
