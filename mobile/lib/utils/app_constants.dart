import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// CONSTANTS
var logger = Logger(printer: PrettyPrinter(),);

/// NAVIGATION
void navigateTo(BuildContext context, Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

void navigateAndReplace(BuildContext context, Widget page) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}

void navigateAndRemoveAll(context, page) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => page),
    (Route<dynamic> route) => false
  );
}
