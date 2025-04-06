import 'package:flutter/material.dart';
import 'package:mobile/data/repository/build_repository.dart';
import 'package:mobile/utils/app_constants.dart';
import 'package:mobile/utils/dialog_widgets.dart';
import 'package:mobile/presentation/connected_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/utils/custom_painters.dart';
import 'package:mobile/utils/jetbrains_brand_theme.dart';

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
    final size = MediaQuery.of(context).size;
    final files = (fixData['files'] as List<dynamic>).cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: JetBrandTheme.backgroundDark,
      body: Stack(
        children: [
          // Animated Background
          CustomPaint(
            size: Size(size.width, size.height),
            painter: GlowingGradientPainter(
              touchPoint: null,
              touchRadius: 0,
              animationValue: 0,
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Section
                Container(
                  margin: EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_fix_high_rounded,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Fix Suggestions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${files.length} file${files.length == 1 ? '' : 's'} to fix',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: files.map((file) {
                        final path = file['path'] ?? 'Unknown path';
                        final explanation = file['explanation'] ?? 'No explanation provided.';
                        final rawCode = file['code']?.toString().replaceAll('```java', '').replaceAll('```', '') ?? '';
                        final lines = rawCode.split('\n');
                        final affectedLines = (file['linesAffected'] as List<dynamic>?)?.cast<int>() ?? [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                JetBrandTheme.surfaceDark.withOpacity(0.9),
                                JetBrandTheme.surfaceDark.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // File Header
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.folder_rounded,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Path',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      path,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Explanation
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.lightbulb_rounded,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Explanation',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      explanation,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Code
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: JetBrandTheme.buttonGradient,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.code_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Suggested Changes',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: JetBrandTheme.backgroundDark.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: List.generate(lines.length, (i) {
                                            // Skip empty first line if it exists
                                            if (i == 0 && lines[i].trim().isEmpty) {
                                              return const SizedBox.shrink();
                                            }
                                            
                                            final isHighlighted = affectedLines.contains(i);
                                            return Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 40,
                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                  child: Text(
                                                    '${i + 1}',
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.5),
                                                      fontSize: 14,
                                                      fontFamily: 'monospace',
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Container(
                                                  width: 800,
                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                  decoration: isHighlighted
                                                      ? BoxDecoration(
                                                          color: Colors.green.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        )
                                                      : null,
                                                  child: Text(
                                                    lines[i],
                                                    style: TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontSize: 14,
                                                      color: isHighlighted
                                                          ? Colors.green
                                                          : Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Bottom Action Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _retryFixRequest,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry AI Fix'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange.withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _applyFix,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Apply Fix'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green.withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
