import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/utils/app_constants.dart';
import '../repository/connection_repository.dart';
import '../domain/connection_status.dart';
import 'package:http/http.dart' as http;

final connectionRepositoryProvider = Provider((ref) => ConnectionRepository());

final connectionStatusProvider = StateNotifierProvider<ConnectionStatusNotifier, ConnectionStatus>((ref) {
  final repo = ref.read(connectionRepositoryProvider);
  return ConnectionStatusNotifier(repo);
});

class ConnectionStatusNotifier extends StateNotifier<ConnectionStatus> {
  final ConnectionRepository _repository;
  Timer? _pollTimer;
  String? _currentUrl;

  ConnectionStatusNotifier(this._repository) : super(ConnectionStatus.idle);

  Future<bool> connect(String baseUrl) async {
    state = ConnectionStatus.connecting;
    
    final ok = await _repository.ping(baseUrl);
    if (ok) {
      _currentUrl = baseUrl;
      state = ConnectionStatus.connected;
      _startPolling();
      return true;
    } else {
      state = ConnectionStatus.error;
      return false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_currentUrl == null) return;
      try {
        final ok = await _repository.ping(_currentUrl!);
        if (!ok) {
          state = ConnectionStatus.disconnected;
          _pollTimer?.cancel();
        }
      } catch (_) {
        state = ConnectionStatus.disconnected;
        _pollTimer?.cancel();
      }
    });
  }

  static Future<bool> ping(String baseUrl) async {
    
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

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    state = ConnectionStatus.disconnected;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
