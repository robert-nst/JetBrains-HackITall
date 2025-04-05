import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/connection_repository.dart';
import '../connection_status.dart';

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

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
