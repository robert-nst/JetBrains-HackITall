import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/build_repository.dart';

final buildRepositoryProvider = Provider((ref) => BuildRepository());

final buildProvider = StateNotifierProvider<BuildNotifier, Map<String, dynamic>?>((ref) {
  final repo = ref.read(buildRepositoryProvider);
  return BuildNotifier(repo);
});

class BuildNotifier extends StateNotifier<Map<String, dynamic>?> {
  final BuildRepository _repo;
  Timer? _pollTimer;

  BuildNotifier(this._repo) : super(null);

  
  Future<void> run(String baseUrl) async {
    // Set initial "in progress" state for UI feedback
    state = {
      "status": "running",
      "message": "Build started"
    };

    final result = await _repo.runBuild(baseUrl);

    if (result['success'] == false) {
      state = {
        "status": "error",
        "message": result['message']
      };
      return;
    }

    _startPolling(baseUrl);
  }

  void _startPolling(String baseUrl) {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final result = await _repo.getBuildStatus(baseUrl);

      // if (result == null) {
      //   state = {
      //     "status": "error",
      //     "message": "Failed to get build status"
      //   };
      //   _pollTimer?.cancel();
      //   return;
      // }

      if (result != null) {
        state = result;

        final status = result['status'].toString().toLowerCase();
        if (status != "running") {
          _pollTimer?.cancel();
        }
      }
    });
  }

  void setState(Map<String, dynamic> data) {
    state = data;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
