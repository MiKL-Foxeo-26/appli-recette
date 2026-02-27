import 'package:flutter/material.dart';

/// Palette "Chaleur & Appétit"
abstract class AppColors {
  // Primary
  static const Color primary = Color(0xFFE8794A);
  static const Color primaryLight = Color(0xFFF0A07A);
  static const Color primaryDark = Color(0xFFBF5A2F);

  // Secondary
  static const Color secondary = Color(0xFFF5C26B);
  static const Color secondaryLight = Color(0xFFF9D99A);
  static const Color secondaryDark = Color(0xFFC99A3F);

  // Background
  static const Color background = Color(0xFFFDF6EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5EDE4);

  // Semantic
  static const Color success = Color(0xFF6BAE75);
  static const Color error = Color(0xFFC0392B);
  static const Color warning = Color(0xFFF0A500);
  static const Color info = Color(0xFF4A90D9);

  // Neutral
  static const Color textPrimary = Color(0xFF2C1A0E);
  static const Color textSecondary = Color(0xFF7A5C44);
  static const Color textHint = Color(0xFFB89880);
  static const Color divider = Color(0xFFE8D5C4);
  static const Color disabled = Color(0xFFCCBBAA);

  // Planning grid
  static const Color midiBackground = Color(0xFFFFF8E1);
  static const Color soirBackground = Color(0xFFE8EAF6);

  // Ratings
  static const Color liked = Color(0xFF6BAE75);
  static const Color neutral = Color(0xFFB89880);
  static const Color disliked = Color(0xFFC0392B);
}
