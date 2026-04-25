import 'package:ecua_inventario/app/router/app_router.dart';
import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/app/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EcuaInventarioApp extends ConsumerWidget {
  const EcuaInventarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'EcuaInventario',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(themeState.seedColor, Brightness.light),
      darkTheme: buildTheme(themeState.seedColor, Brightness.dark),
      themeMode: themeState.themeMode,
      routerConfig: appRouter,
    );
  }
}
