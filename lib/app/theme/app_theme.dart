import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kBrandNavy = Color(0xFF0F2044);
const Color kBrandAmber = Color(0xFFF59E0B);
const Color kDefaultSeedColor = kBrandNavy;

ThemeData buildTheme(Color seedColor, Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  final textTheme = GoogleFonts.interTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: brightness == Brightness.dark
          ? const Color(0xFF1A1A2E)
          : Colors.white,
      indicatorColor: kBrandAmber.withValues(alpha: 0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: kBrandNavy);
        }
        return const IconThemeData(color: Color(0xFF9E9E9E));
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: kBrandNavy);
        }
        return GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9E9E9E));
      }),
    ),
  );
}
