import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E3A37);
  static const Color primaryDark = Color(0xFF142A27);
  static const Color primaryLight = Color(0xFF2E5951);
  static const Color accent = Color(0xFF68B69E);
  static const Color accentStrong = Color(0xFF3F8B74);
  static const Color accentSoft = Color(0xFFDDEEE6);
  static const Color gold = Color(0xFFD6B872);
  static const Color background = Color(0xFFEAE4D7);
  static const Color surface = Color(0xFFFFFCF8);
  static const Color surfaceMuted = Color(0xFFEEE6D9);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryLight, primary, primaryDark],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF274B45), Color(0xFF1E3A37), Color(0xFF132825)],
  );
}
