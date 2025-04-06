import 'package:flutter/material.dart';

class FixSuggestionPage extends StatelessWidget {
  final Map<String, dynamic> fixData;

  const FixSuggestionPage({super.key, required this.fixData});

  @override
  Widget build(BuildContext context) {
    final files = (fixData['files'] as List<dynamic>).cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(title: const Text('AI Fix Suggestions')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: files.length,
        separatorBuilder: (_, __) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          final file = files[index];
          final path = file['path'] ?? 'Unknown path';
          final code = file['code']?.toString().replaceAll('```java', '').replaceAll('```', '') ?? '';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                path,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
