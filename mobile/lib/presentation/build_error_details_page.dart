import 'package:flutter/material.dart';
import 'package:mobile/data/repository/build_repository.dart';
import 'package:mobile/presentation/fix_suggestion_page.dart';
import 'package:mobile/utils/app_constants.dart';
import 'package:mobile/utils/dialog_widgets.dart';

class BuildErrorDetailsPage extends StatelessWidget {
  final Map<String, dynamic> buildData;
  final String baseUrl;

  const BuildErrorDetailsPage({super.key, required this.buildData, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    final errorMessage = buildData['errorMessage'] ?? 'Unknown error';
    final errorCode = buildData['errorCode'] as Map<String, dynamic>?;

    final line = errorCode?['line'];
    final before = (errorCode?['before'] as List<dynamic>?)?.cast<String>() ?? [];
    final error = errorCode?['error'] ?? '';
    final after = (errorCode?['after'] as List<dynamic>?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Build Error Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error Message:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(errorMessage),
              const SizedBox(height: 24),

              Text(
                'Code Context (Error on line $line):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // BEFORE
              ...before.map((line) => Text(line, style: const TextStyle(color: Colors.grey))),

              // ERROR LINE (highlighted)
              Container(
                color: Colors.red.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),

              // AFTER
              ...after.map((line) => Text(line, style: const TextStyle(color: Colors.grey))),

              const SizedBox(height: 32),

              // GET FIX BUTTON
              ElevatedButton(
                onPressed: () => _handleFixWithAI(context),
                child: const Text("Fix with AI"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFixWithAI(BuildContext context) async {
    loadingDialog(context);

    final repo = BuildRepository(); // or get from ref if you're using Riverpod

    final result = await repo.requestFix(baseUrl);

    if (result != null && result['success'] == true) {
      Navigator.pop(context); // close loading dialog
      navigateTo(context, FixSuggestionPage(initialFixData: result, baseUrl: baseUrl));
    } else {
      Navigator.pop(context); // close loading dialog
      errorDialog(context, "Could not fetch fix suggestions.");
    }
  }

}
