import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Stadium night theme
  static const Color bg = Color(0xFF020817);
  static const Color bg2 = Color(0xFF061B2E);

  static const Color card = Color(0xFF071827);
  static const Color card2 = Color(0xFF0B2436);

  static const Color pitchGreen = Color(0xFF20D66B);
  static const Color stadiumBlue = Color(0xFF38BDF8);
  static const Color deepBlue = Color(0xFF0F2A44);

  static const Color accent = pitchGreen;
  static const Color accent2 = stadiumBlue;

  static const Color gold = Color(0xFFFFD166);
  static const Color text = Color(0xFFF8FAFC);
  static const Color subText = Color(0xFFB7C7D8);
  static const Color border = Color(0xFF24516B);

  // Old names used by existing widgets
  static const Color neonGreen = pitchGreen;
  static const Color white = text;

  static ThemeData get theme {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: pitchGreen,
        secondary: stadiumBlue,
        surface: card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF061523).withOpacity(0.88),
        hintStyle: const TextStyle(color: subText),
        prefixIconColor: subText,
        suffixIconColor: text,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border.withOpacity(0.75)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: pitchGreen, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => theme;
}
