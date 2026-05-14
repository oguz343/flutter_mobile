import 'package:flutter/material.dart';

class AppTheme {
  static const Color dark = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color soft = Color(0xFFF8FAFC);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color purple = Color(0xFF4F46E5);
  static const Color green = Color(0xFF10B981);
  static const Color orange = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> coloredShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.22),
          blurRadius: 34,
          offset: const Offset(0, 18),
        ),
      ];

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: purple,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: purple,
        selectionColor: Color(0x334F46E5),
        selectionHandleColor: purple,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: const TextStyle(
          color: muted,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: purple,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: red,
            width: 1.6,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: purple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: purple,
          side: const BorderSide(
            color: Color(0xFFD8B4FE),
          ),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: dark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: const TextStyle(
          color: dark,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
        contentTextStyle: const TextStyle(
          color: muted,
          fontWeight: FontWeight.w700,
          height: 1.45,
        ),
      ),
    );
  }
}