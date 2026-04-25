import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keySeedColor = 'seed_color';
const _keyThemeMode = 'theme_mode';

class ThemeState {
  const ThemeState({
    required this.seedColor,
    required this.themeMode,
  });

  final Color seedColor;
  final ThemeMode themeMode;

  ThemeState copyWith({Color? seedColor, ThemeMode? themeMode}) => ThemeState(
        seedColor: seedColor ?? this.seedColor,
        themeMode: themeMode ?? this.themeMode,
      );
}

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    _loadFromPrefs();
    return const ThemeState(seedColor: kDefaultSeedColor, themeMode: ThemeMode.system);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_keySeedColor);
    final modeIndex = prefs.getInt(_keyThemeMode);
    state = ThemeState(
      seedColor: colorValue != null ? Color(colorValue) : kDefaultSeedColor,
      themeMode: modeIndex != null ? ThemeMode.values[modeIndex] : ThemeMode.system,
    );
  }

  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySeedColor, color.toARGB32());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
