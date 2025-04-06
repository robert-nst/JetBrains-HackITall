import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:mobile/data/repository/build_repository.dart';
import 'package:mobile/presentation/fix_suggestion_page.dart';
import 'package:mobile/utils/app_constants.dart';
import 'package:mobile/utils/custom_painters.dart';
import 'package:mobile/utils/dialog_widgets.dart';
import 'package:mobile/utils/jetbrains_brand_theme.dart';

class BuildErrorDetailsPage extends StatefulWidget {
  final Map<String, dynamic> buildData;
  final String baseUrl;

  const BuildErrorDetailsPage({super.key, required this.buildData, required this.baseUrl});

  @override
  State<BuildErrorDetailsPage> createState() => _BuildErrorDetailsPageState();
}

class _BuildErrorDetailsPageState extends State<BuildErrorDetailsPage> {
  late List<String> _codeLines;
  late int _errorLineIndex;
  bool _hasChanges = false;
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    final errorCode = widget.buildData['errorCode'] as Map<String, dynamic>?;
    final before = (errorCode?['before'] as List<dynamic>?)?.cast<String>() ?? [];
    final error = errorCode?['error'] ?? '';
    final after = (errorCode?['after'] as List<dynamic>?)?.cast<String>() ?? [];
    
    _codeLines = [...before, error, ...after];
    _errorLineIndex = before.length;
    
    // Initialize controllers for each line
    for (var line in _codeLines) {
      _controllers.add(TextEditingController(text: line));
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleCodeChange(int index, String newValue) {
    setState(() {
      _codeLines[index] = newValue;
      _hasChanges = true;
    });
  }

  Future<void> _handleSaveChanges() async {
    if (!_hasChanges) return;

    loadingDialog(context);

    try {
      final repo = BuildRepository();
      final result = await repo.saveCodeChanges(
        widget.baseUrl,
        _codeLines,
        widget.buildData['errorCode']?['line'] ?? 0,
      );

      if (result != null && result['success'] == true) {
        Navigator.pop(context); // close loading dialog
        successDialog(context, "Changes saved successfully!");
        setState(() => _hasChanges = false);
      } else {
        Navigator.pop(context); // close loading dialog
        errorDialog(context, "Could not save changes.");
      }
    } catch (e) {
      Navigator.pop(context); // close loading dialog
      errorDialog(context, "An error occurred while saving changes.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final errorMessage = widget.buildData['errorMessage'] ?? 'Unknown error';
    final errorCode = widget.buildData['errorCode'] as Map<String, dynamic>?;
    final line = errorCode?['line'];

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
                // Top Section with Connection Status
                Container(
                  margin: EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Build Error Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Line $line',
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error Summary Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.red.withOpacity(0.2),
                                Colors.red.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
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
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Error Summary',
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
                                errorMessage,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Code Context
                        Container(
                          padding: const EdgeInsets.all(24),
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
                                    'Code Context',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Code Content with Syntax Highlighting
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: JetBrandTheme.backgroundDark.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Line numbers and code
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Line numbers column
                                        Container(
                                          padding: const EdgeInsets.only(right: 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: List.generate(
                                              _codeLines.length,
                                              (index) => SizedBox(
                                                height: 24,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                                  decoration: index == _errorLineIndex
                                                      ? BoxDecoration(
                                                          color: Colors.red.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        )
                                                      : null,
                                                  child: Text(
                                                    '${line - _errorLineIndex + index}',
                                                    style: TextStyle(
                                                      color: index == _errorLineIndex
                                                          ? Colors.red
                                                          : Colors.white.withOpacity(0.3),
                                                      fontFamily: 'monospace',
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Code with syntax highlighting
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: List.generate(
                                                _codeLines.length,
                                                (index) => SizedBox(
                                                  height: 24,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    decoration: index == _errorLineIndex
                                                        ? BoxDecoration(
                                                            color: Colors.red.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(4),
                                                          )
                                                        : null,
                                                    child: SizedBox(
                                                      width: 800, // Fixed width to allow horizontal scrolling
                                                      child: TextField(
                                                        controller: _controllers[index],
                                                        onChanged: (value) => _handleCodeChange(index, value),
                                                        style: TextStyle(
                                                          fontFamily: 'monospace',
                                                          fontSize: 14,
                                                          color: index == _errorLineIndex
                                                              ? Colors.red
                                                              : Colors.white,
                                                        ),
                                                        decoration: const InputDecoration(
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.zero,
                                                          border: InputBorder.none,
                                                          focusedBorder: InputBorder.none,
                                                          enabledBorder: InputBorder.none,
                                                          errorBorder: InputBorder.none,
                                                          disabledBorder: InputBorder.none,
                                                        ),
                                                        cursorColor: Colors.white.withOpacity(0.5),
                                                        cursorWidth: 1,
                                                        cursorHeight: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _hasChanges ? _handleSaveChanges : () => _handleFixWithAI(context),
                          icon: Icon(_hasChanges ? Icons.save_rounded : Icons.auto_fix_high_rounded),
                          label: Text(_hasChanges ? 'Save Changes' : 'Fix with AI'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: _hasChanges 
                                ? Colors.blue.withOpacity(0.3)
                                : Colors.green.withOpacity(0.3),
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

  void _handleFixWithAI(BuildContext context) async {
    loadingDialog(context);

    final repo = BuildRepository();

    final result = await repo.requestFix(widget.baseUrl);

    if (result != null && result['success'] == true) {
      Navigator.pop(context); // close loading dialog
      navigateTo(context, FixSuggestionPage(fixData: result));
    } else {
      Navigator.pop(context); // close loading dialog
      errorDialog(context, "Could not fetch fix suggestions.");
    }
  }
}
