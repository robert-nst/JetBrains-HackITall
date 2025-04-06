import 'package:flutter/material.dart';
import 'package:mobile/data/repository/build_repository.dart';
import 'package:mobile/utils/app_constants.dart';
import 'package:mobile/utils/dialog_widgets.dart';
import 'package:mobile/presentation/connected_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FixSuggestionPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialFixData;
  final String baseUrl;

  const FixSuggestionPage({
    super.key,
    required this.initialFixData,
    required this.baseUrl,
  });

  @override
  ConsumerState<FixSuggestionPage> createState() => _FixSuggestionPageState();
}

class _FixSuggestionPageState extends ConsumerState<FixSuggestionPage> {
  late Map<String, dynamic> fixData;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fixData = widget.initialFixData;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _retryFixRequest() async {
    loadingDialog(context);

    final repo = BuildRepository();
    final result = await repo.requestFix(widget.baseUrl);

    Navigator.pop(context); // Close loading dialog

    if (result != null && result['success'] == true) {
      setState(() {
        fixData = result;
      });

      successDialogWithFunction(
        context,
        "New AI fix suggestion received.",
        "Check them out",
        onConfirm: () {
          // Navigator.pop(context); // Close the dialog first
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      );
    } else {
      errorDialog(context, "Failed to retrieve fix suggestions.");
    }
  }

  Future<void> _applyFix() async {
    loadingDialog(context);

    final repo = BuildRepository();
    final result = await repo.applyFix(widget.baseUrl);

    Navigator.pop(context); // Close loading alert

    if (result != null && result['success'] == true) {
      successDialogWithFunction(
        context,
        "Fix applied successfully.",
        "Run build",
        onConfirm: () async {
          Navigator.pop(context);

          // Wait just enough for the pop to complete cleanly
          await Future.delayed(const Duration(milliseconds: 200));

          navigateAndRemoveAll(context, ConnectedScreen(url: widget.baseUrl, autoRunBuild: true));
        },
      );
    } else {
      errorDialog(context, "Failed to apply fix.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = (fixData['files'] as List<dynamic>).cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(title: const Text('AI Fix Suggestions')),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: files.length + 1, // +1 for the buttons at the bottom
        itemBuilder: (context, index) {
          if (index == files.length) {
            return Column(
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _retryFixRequest,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text("Retry AI Fix"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFix,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("Apply Fix"),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          final file = files[index];
          final path = file['path'] ?? 'Unknown path';
          final explanation = file['explanation'] ?? 'No explanation provided.';
          final rawCode = file['code']?.toString().replaceAll('```java', '').replaceAll('```', '') ?? '';
          final lines = rawCode.split('\n');
          final affectedLines = (file['linesAffected'] as List<dynamic>?)?.cast<int>() ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧠 Explanation
              Text("Explanation:", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(explanation, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),

              // 📄 File path
              Text(
                path,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),

              // 💻 Code block
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(lines.length, (i) {
                        final isHighlighted = affectedLines.contains(i + 1);
                        return Container(
                          // width: double.infinity,
                          color: isHighlighted ? Colors.green.withOpacity(0.2) : null,
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                          child: Text(
                            lines[i],
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (index < files.length - 1) const Divider(thickness: 1.2),
            ],
          );
        },
      ),
    );
  }
}
