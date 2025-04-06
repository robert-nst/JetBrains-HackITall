import 'package:flutter/material.dart';

class CustomTheme {
  const CustomTheme();

  static const Color blue = Color(0xFF049DD9);
  static const Color darkBlue1 = Color(0xFF055BA6);
  static const Color darkBlue2 = Color(0xFF023E73);
  static const Color darkBlue3 = Color.fromARGB(255, 14, 36, 64);

  static const Color blueGrey = Color(0xFF3A6D8C);
  static const Color darkGrey = Color.fromARGB(255, 67, 67, 67);

  static const Color white = Color(0xFFFFFFFF);
  static const Color dirtyWhite = Color(0xFFE9F0F2);

  static const Color loginButtonColor = Color.fromARGB(255, 32, 46, 65);
  static const Color cursorColor = Colors.black;

  static const Color gradientStart1 = Color.fromARGB(255, 12, 104, 184);
  static const Color gradientEnd1 = darkBlue3;

  static const Color gradientStart2 = Color.fromARGB(255, 154, 191, 214);
  static const Color gradientEnd2 = darkBlue3;

  static const Color cardStyle1 = Color.fromARGB(255, 42, 42, 42);
  static const Color cardStyle2 = Color(0xFF12E195);
  static const Color cardStyle3 = Color(0xFFAD88C6);
  static const Color cardStyle4 = Color(0xFFFFBE98);
  static const int cardStyleCount = 4;

  static const LinearGradient loginGradient = LinearGradient(
    colors: <Color>[gradientStart2, gradientEnd2],
    stops: <double>[0.0, 0.9],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
