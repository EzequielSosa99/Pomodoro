import 'package:flutter/material.dart';

// Color palette definitions
class ColorPalette {
  final String id;
  final Color lightAccent;
  final Color lightAccentSecondary;
  final Color lightBackground;
  final Color lightSurface;
  final Color darkAccent;
  final Color darkAccentSecondary;

  const ColorPalette({
    required this.id,
    required this.lightAccent,
    required this.lightAccentSecondary,
    required this.lightBackground,
    required this.lightSurface,
    required this.darkAccent,
    required this.darkAccentSecondary,
  });
}

// Available color palettes
class AppPalettes {
  static const lavender = ColorPalette(
    id: 'lavender',
    lightAccent: Color(0xFFB4A5D6),
    lightAccentSecondary: Color(0xFFD4B5C9),
    lightBackground: Color(0xFFFAF8F5),
    lightSurface: Color(0xFFFFFBF7),
    darkAccent: Color(0xFFC5B8DB),
    darkAccentSecondary: Color(0xFFDEC5D4),
  );

  static const mint = ColorPalette(
    id: 'mint',
    lightAccent: Color(0xFF9DCDB4),
    lightAccentSecondary: Color(0xFFB4D4C6),
    lightBackground: Color(0xFFF5FAF8),
    lightSurface: Color(0xFFFAFEFC),
    darkAccent: Color(0xFFADD9C2),
    darkAccentSecondary: Color(0xFFC2E0D2),
  );

  static const peach = ColorPalette(
    id: 'peach',
    lightAccent: Color(0xFFFFB4A5),
    lightAccentSecondary: Color(0xFFFFCDB4),
    lightBackground: Color(0xFFFFF8F5),
    lightSurface: Color(0xFFFFFCFA),
    darkAccent: Color(0xFFFFCDBD),
    darkAccentSecondary: Color(0xFFFFDCCE),
  );

  static const sky = ColorPalette(
    id: 'sky',
    lightAccent: Color(0xFFA5C9E6),
    lightAccentSecondary: Color(0xFFB4D9F0),
    lightBackground: Color(0xFFF5F8FA),
    lightSurface: Color(0xFFFAFCFE),
    darkAccent: Color(0xFFB8D9ED),
    darkAccentSecondary: Color(0xFFC9E3F5),
  );

  static const rose = ColorPalette(
    id: 'rose',
    lightAccent: Color(0xFFE6A5C9),
    lightAccentSecondary: Color(0xFFF0B4D9),
    lightBackground: Color(0xFFFAF5F8),
    lightSurface: Color(0xFFFEFAFC),
    darkAccent: Color(0xFFEDB8D9),
    darkAccentSecondary: Color(0xFFF5C9E3),
  );

  static const sage = ColorPalette(
    id: 'sage',
    lightAccent: Color(0xFFB4C9A5),
    lightAccentSecondary: Color(0xFFC6D9B4),
    lightBackground: Color(0xFFF8FAF5),
    lightSurface: Color(0xFFFCFEFA),
    darkAccent: Color(0xFFC2D9B8),
    darkAccentSecondary: Color(0xFFD2E3C9),
  );

  static List<ColorPalette> get all => [
        lavender,
        mint,
        peach,
        sky,
        rose,
        sage,
      ];

  static ColorPalette getById(String id) {
    return all.firstWhere(
      (palette) => palette.id == id,
      orElse: () => lavender,
    );
  }
}

// App theme configuration with pastel colors and chill vibes
class AppTheme {
  // Common colors
  static const Color lightTextPrimary = Color(0xFF2D3748);
  static const Color lightTextSecondary = Color(0xFF718096);
  static const Color lightBorder = Color(0xFFE8DED2);
  static const Color lightSuccess = Color(0xFFA8D5BA);
  static const Color lightWarning = Color(0xFFF5D9A8);
  static const Color lightError = Color(0xFFEFB3B3);

  static const Color darkBackground = Color(0xFF1A1D2E);
  static const Color darkSurface = Color(0xFF25293D);
  static const Color darkTextPrimary = Color(0xFFF0EDE6);
  static const Color darkTextSecondary = Color(0xFFB8B5AB);
  static const Color darkBorder = Color(0xFF3A3E52);
  static const Color darkSuccess = Color(0xFFB8D9C5);
  static const Color darkWarning = Color(0xFFFFDDB3);
  static const Color darkError = Color(0xFFF5C3C3);

  // Get light theme with specific palette
  static ThemeData getLightTheme(ColorPalette palette) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: palette.lightBackground,
      colorScheme: ColorScheme.light(
        primary: palette.lightAccent,
        secondary: palette.lightAccentSecondary,
        surface: palette.lightSurface,
        background: palette.lightBackground,
        error: lightError,
        primaryContainer: palette.lightAccent.withOpacity(0.2),
        secondaryContainer: palette.lightAccentSecondary.withOpacity(0.2),
        tertiary: palette.lightAccentSecondary,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
          letterSpacing: 0.15,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: lightTextPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: lightTextSecondary,
          letterSpacing: 0.25,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: lightTextSecondary,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.lightSurface,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: lightBorder.withOpacity(0.5), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.lightAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: palette.lightAccent.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.lightAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightBorder.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lightBorder.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.lightAccent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      dividerColor: lightBorder.withOpacity(0.5),
      iconTheme: IconThemeData(
        color: palette.lightAccent,
        size: 24,
      ),
    );
  }

  // Get dark theme with specific palette
  static ThemeData getDarkTheme(ColorPalette palette) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: palette.darkAccent,
        secondary: palette.darkAccentSecondary,
        surface: darkSurface,
        background: darkBackground,
        error: darkError,
        primaryContainer: palette.darkAccent.withOpacity(0.2),
        secondaryContainer: palette.darkAccentSecondary.withOpacity(0.2),
        tertiary: palette.darkAccentSecondary,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
          letterSpacing: 0.15,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkTextPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: darkTextSecondary,
          letterSpacing: 0.25,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkTextSecondary,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: darkBorder.withOpacity(0.5), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.darkAccent,
          foregroundColor: darkBackground,
          elevation: 0,
          shadowColor: palette.darkAccent.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.darkAccent,
        foregroundColor: darkBackground,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkBorder.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkBorder.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.darkAccent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      dividerColor: darkBorder.withOpacity(0.5),
      iconTheme: IconThemeData(
        color: palette.darkAccent,
        size: 24,
      ),
    );
  }

  // Legacy support - default themes
  static ThemeData get lightTheme => getLightTheme(AppPalettes.lavender);
  static ThemeData get darkTheme => getDarkTheme(AppPalettes.lavender);
}
