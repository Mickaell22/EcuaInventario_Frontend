import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/app/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        foregroundColor: Colors.white,
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _Section(
            title: 'Apariencia',
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Modo de pantalla'),
                trailing: DropdownButton<ThemeMode>(
                  value: themeState.themeMode,
                  underline: const SizedBox(),
                  onChanged: (mode) {
                    if (mode != null) notifier.setThemeMode(mode);
                  },
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('Automático')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Color del negocio'),
                trailing: _ColorDot(color: themeState.seedColor),
                onTap: () =>
                    _showColorPicker(context, themeState.seedColor, notifier),
              ),
            ],
          ),
          _Section(
            title: 'Negocio',
            children: [
              const ListTile(
                leading: Icon(Icons.store_outlined),
                title: Text('Nombre del negocio'),
                trailing: Icon(Icons.chevron_right),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Datos personales'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
          _Section(
            title: 'Cuenta',
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                title: const Text(
                    'Cerrar sesión', style: TextStyle(color: Color(0xFFEF4444))),
                onTap: () => context.go('/login'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showColorPicker(
      BuildContext context, Color current, ThemeNotifier notifier) {
    const colors = [
      Color(0xFF0F2044),
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFFC62828),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
      Color(0xFFE65100),
      Color(0xFF283593),
    ];
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Color de tu negocio',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Define el color principal de tu app',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final c in colors)
                  GestureDetector(
                    onTap: () {
                      notifier.setSeedColor(c);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: c.toARGB32() == current.toARGB32()
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: c.toARGB32() == current.toARGB32()
                            ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 10)]
                            : [],
                      ),
                      child: c.toARGB32() == current.toARGB32()
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: kBrandAmber,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
