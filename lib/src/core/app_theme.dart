import 'package:flutter/material.dart';

class AppTheme {
  static const Color dark = Color(0xFF101828);
  static const Color muted = Color(0xFF667085);
  static const Color soft = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE4E7EC);
  static const Color cyan = Color(0xFF0891B2);
  static const Color purple = Color(0xFF4F46E5);
  static const Color green = Color(0xFF059669);
  static const Color orange = Color(0xFFD97706);
  static const Color red = Color(0xFFDC2626);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF101828).withValues(alpha: 0.07),
      blurRadius: 30,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.82),
      blurRadius: 1,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> coloredShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.20),
      blurRadius: 32,
      offset: const Offset(0, 16),
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
        primary: purple,
        secondary: cyan,
        tertiary: green,
        error: red,
        surface: surface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: soft,
      primaryColor: purple,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      splashColor: purple.withValues(alpha: 0.08),
      highlightColor: purple.withValues(alpha: 0.05),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: dark, size: 22),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: soft,
        foregroundColor: dark,
        titleTextStyle: TextStyle(
          color: dark,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
      ),
      textTheme: base.textTheme
          .apply(bodyColor: dark, displayColor: dark)
          .copyWith(
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              color: muted,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: purple,
        selectionColor: Color(0x334F46E5),
        selectionHandleColor: purple,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        floatingLabelStyle: const TextStyle(
          color: purple,
          fontWeight: FontWeight.w900,
        ),
        labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w800),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: Color(0xFF98A2B3),
        suffixIconColor: Color(0xFF98A2B3),
        errorStyle: const TextStyle(fontWeight: FontWeight.w800),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: purple, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: red, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: purple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE4E7EC),
          disabledForegroundColor: const Color(0xFF98A2B3),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: purple,
          side: const BorderSide(color: Color(0xFFC7D2FE)),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: purple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: line),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: purple,
        linearTrackColor: Color(0xFFE4E7EC),
        circularTrackColor: Color(0xFFE4E7EC),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return purple;
          }

          return Colors.white;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: Color(0xFFD0D5DD), width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF2F4F7),
        selectedColor: purple.withValues(alpha: 0.12),
        disabledColor: const Color(0xFFF2F4F7),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(
          color: dark,
          fontWeight: FontWeight.w800,
          fontSize: 12,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        headerBackgroundColor: purple,
        headerForegroundColor: Colors.white,
        dayShape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        dialBackgroundColor: const Color(0xFFF2F4F7),
        dialHandColor: purple,
        hourMinuteColor: const Color(0xFFF2F4F7),
        hourMinuteTextColor: dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
