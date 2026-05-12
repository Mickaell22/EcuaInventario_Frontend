import 'dart:convert';
import 'dart:io';

import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/core/api/api_client.dart';
import 'package:ecua_inventario/features/auth/login_screen.dart';
import 'package:ecua_inventario/features/auth/register_screen.dart';
import 'package:ecua_inventario/features/chat/chat_screen.dart';
import 'package:ecua_inventario/features/home/home_screen.dart';
import 'package:ecua_inventario/features/onboarding/onboarding_screen.dart';
import 'package:ecua_inventario/features/products/movement_screen.dart';
import 'package:ecua_inventario/features/products/product_detail_screen.dart';
import 'package:ecua_inventario/features/products/products_screen.dart';
import 'package:ecua_inventario/features/profile/profile_screen.dart';
import 'package:ecua_inventario/features/settings/settings_screen.dart';
import 'package:ecua_inventario/features/suppliers/supplier_detail_screen.dart';
import 'package:ecua_inventario/features/suppliers/suppliers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _publicRoutes = {'/splash', '/onboarding', '/login', '/register'};
const _routerStorage = FlutterSecureStorage();

bool _isJwtExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map<String, dynamic>;
    final exp = payload['exp'] as int?;
    if (exp == null) return true;
    return DateTime.now().isAfter(
      DateTime.fromMillisecondsSinceEpoch(exp * 1000),
    );
  } catch (_) {
    return true;
  }
}

Future<String?> _authRedirect(BuildContext context, GoRouterState state) async {
  final location = state.matchedLocation;
  if (_publicRoutes.contains(location)) return null;

  final token = await _routerStorage.read(key: 'access_token');
  if (token == null || _isJwtExpired(token)) return '/login';
  return null;
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: sessionExpiredNotifier,
  redirect: _authRedirect,
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    const ProductDetailScreen(productId: null),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ProductDetailScreen(productId: state.pathParameters['id']),
                routes: [
                  GoRoute(
                    path: 'move',
                    builder: (context, state) =>
                        MovementScreen(productId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/suppliers',
            builder: (context, state) => const SuppliersScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    const SupplierDetailScreen(supplierId: null),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    SupplierDetailScreen(supplierId: state.pathParameters['id']),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen()),
        ]),
      ],
    ),
  ],
);

// ── Main shell ──────────────────────────────────────────────────────────────

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<bool> _onWillPop(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Salir de EcuaInventario?'),
        content: const Text('¿Deseas cerrar la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: kBrandNavy),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
          return;
        }
        final shouldExit = await _onWillPop(context);
        if (shouldExit && Platform.isAndroid) await SystemNavigator.pop();
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: _CustomNavBar(
          selectedIndex: navigationShell.currentIndex,
          onSelect: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}

// ── Custom bottom nav with elevated center chat button ──────────────────────

class _CustomNavBar extends StatelessWidget {
  const _CustomNavBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 64 + bottomPad,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Bar background + border
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(color: cs.outlineVariant, width: 0.5),
                ),
              ),
            ),
          ),
          // Nav items — 4 items with an empty center slot
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 64,
            child: Row(
              children: [
                _NavBarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Inicio',
                  selected: selectedIndex == 0,
                  activeColor: kBrandNavy,
                  inactiveColor: cs.onSurfaceVariant,
                  onTap: () => onSelect(0),
                ),
                _NavBarItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: 'Inventario',
                  selected: selectedIndex == 1,
                  activeColor: kBrandNavy,
                  inactiveColor: cs.onSurfaceVariant,
                  onTap: () => onSelect(1),
                ),
                const Expanded(child: SizedBox()),
                _NavBarItem(
                  icon: Icons.local_shipping_outlined,
                  activeIcon: Icons.local_shipping,
                  label: 'Proveedores',
                  selected: selectedIndex == 3,
                  activeColor: kBrandNavy,
                  inactiveColor: cs.onSurfaceVariant,
                  onTap: () => onSelect(3),
                ),
                _NavBarItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Ajustes',
                  selected: selectedIndex == 4,
                  activeColor: kBrandNavy,
                  inactiveColor: cs.onSurfaceVariant,
                  onTap: () => onSelect(4),
                ),
              ],
            ),
          ),
          // Elevated center chat button
          Positioned(
            top: -18,
            child: _ChatNavButton(
              isActive: selectedIndex == 2,
              surfaceColor: cs.surface,
              onTap: () => onSelect(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Icon(
                selected ? activeIcon : icon,
                size: 22,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatNavButton extends StatelessWidget {
  const _ChatNavButton({
    required this.isActive,
    required this.surfaceColor,
    required this.onTap,
  });

  final bool isActive;
  final Color surfaceColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? kBrandNavy : kBrandAmber,
          border: Border.all(color: surfaceColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: kBrandAmber.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.auto_awesome,
          size: 22,
          color: isActive ? Colors.white : kBrandNavy,
        ),
      ),
    );
  }
}

// ── Splash ──────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final done = prefs.getBool('onboarding_done') ?? false;
    context.go(done ? '/login' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBrandNavy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: kBrandAmber,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kBrandAmber.withValues(alpha: 0.45),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(Icons.restaurant_menu, size: 48, color: kBrandNavy),
            ),
            const SizedBox(height: 24),
            Text(
              'EcuaInventario',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gestión inteligente para tu negocio',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
