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
      indicatorColor: kBrandAmber.withValues(alpha: 0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.primary);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary);
        }
        return GoogleFonts.inter(fontSize: 11, color: colorScheme.onSurfaceVariant);
      }),
    ),
  );
}
