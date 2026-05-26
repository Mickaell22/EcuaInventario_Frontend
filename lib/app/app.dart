import 'package:facilito/app/router/app_router.dart';
import 'package:facilito/app/theme/app_theme.dart';
import 'package:facilito/app/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FacilitoApp extends ConsumerWidget {
  const FacilitoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'Facilito',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(themeState.seedColor, Brightness.light),
      darkTheme: buildTheme(themeState.seedColor, Brightness.dark),
      themeMode: themeState.themeMode,
      routerConfig: appRouter,
    );
  }
}
