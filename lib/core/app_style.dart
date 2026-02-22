import 'package:flutter/material.dart';

class AppStyle {
  // Vibrant Color Palette
  static const Color primary = Color(0xFF2563EB); // Modern Blue
  static const Color secondary = Color(0xFF6366F1); // Indigo
  static const Color accent = Color(0xFFF59E0B); // Amber
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color danger = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Glassmorphism Decoration
  static BoxDecoration glassDecoration({
    required Color color,
    double opacity = 0.1,
    double blur = 10,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
    );
  }

  // Card Decoration
  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    double borderRadius = 16,
    bool showShadow = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: showShadow ? softShadow : null,
      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
    );
  }

  // Typography
  static TextStyle titleStyle = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1E293B),
    letterSpacing: -0.5,
  );

  static TextStyle subtitleStyle = const TextStyle(
    fontSize: 14,
    color: Color(0xFF64748B),
    fontWeight: FontWeight.w500,
  );

  static TextStyle bodyStyle = const TextStyle(
    fontSize: 16,
    color: Color(0xFF334155),
  );

  static TextStyle labelStyle = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
    textBaseline: TextBaseline.alphabetic,
  );
}
