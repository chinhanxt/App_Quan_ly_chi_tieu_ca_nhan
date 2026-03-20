import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E3A37);
  static const Color primaryDark = Color(0xFF142A27);
  static const Color primaryLight = Color(0xFF2D5751);
  static const Color accent = Color(0xFF5FAF9A);
  static const Color accentStrong = Color(0xFF3E8F7B);
  static const Color accentSoft = Color(0xFFDCEFEA);
  static const Color background = Color(0xFFF6F3EF);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF0ECE7);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryLight, primary, primaryDark],
  );
}
