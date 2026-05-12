import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/features/auth/auth_provider.dart';
import 'package:ecua_inventario/features/home/dashboard_models.dart';
import 'package:ecua_inventario/features/home/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ── Quick actions (static) ────────────────────────────────────────────────────

class _QuickAction {
  const _QuickAction(this.icon, this.color, this.label, this.route);
  final IconData icon;
  final Color color;
  final String label;
  final String route;
}

const _kQuickActions = [
  _QuickAction(Icons.swap_vert, Color(0xFF3B82F6), 'Movimiento', '/products'),
  _QuickAction(
      Icons.add_circle_outline, Color(0xFF10B981), 'Producto', '/products/new'),
  _QuickAction(
      Icons.local_shipping_outlined, Color(0xFF8B5CF6), 'Proveedor', '/suppliers'),
  _QuickAction(Icons.auto_awesome, kBrandAmber, 'Asistente', '/chat'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final dashAsync = ref.watch(dashboardProvider);
    final negocio = ref.watch(negocioProvider);
    final usuario = ref.watch(usuarioProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(165),
        child: _HomeAppBar(
          fecha: fecha,
          negocioNombre: negocio?.nombre ?? usuario?.nombre ?? 'Mi negocio',
          dashAsync: dashAsync,
          onProfileTap: () => context.push('/profile'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: dashAsync.when(
          loading: () => ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomPad),
            children: [
              const _SectionLabel('Acciones rápidas'),
              const SizedBox(height: 8),
              const _QuickActionsGrid(),
              const SizedBox(height: 20),
              const _SectionLabel('Indicadores'),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: const [
                  _SkeletonCard(),
                  _SkeletonCard(),
                  _SkeletonCard(),
                  _SkeletonCard(),
                ],
              ),
            ],
          ),
          error: (e, _) => ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomPad),
            children: [
              const _SectionLabel('Acciones rápidas'),
              const SizedBox(height: 8),
              const _QuickActionsGrid(),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('No se pudo cargar el dashboard',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => ref.invalidate(dashboardProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (dashboard) => _DashboardBody(
            dashboard: dashboard,
            bottomPad: bottomPad,
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard, required this.bottomPad});

  final DashboardData dashboard;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomPad),
      children: [
        const _SectionLabel('Acciones rápidas'),
        const SizedBox(height: 8),
        const _QuickActionsGrid(),
        const SizedBox(height: 20),
        const _SectionLabel('Indicadores'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _IndicatorCard(
              label: 'Utilidad del día',
              value: '\$${dashboard.utilidad.toStringAsFixed(2)}',
              sub: dashboard.utilidad >= 0 ? 'Positiva ✓' : 'Negativa ⚠',
              dotColor: dashboard.utilidad >= 0
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFEF4444),
            ),
            _IndicatorCard(
              label: 'Stock crítico',
              value: '${dashboard.stockCriticoCount} items',
              sub: dashboard.stockCriticoCount == 0
                  ? 'Todo en orden ✓'
                  : 'Requiere atención',
              dotColor: dashboard.stockCriticoCount == 0
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFF59E0B),
            ),
            _IndicatorCard(
              label: 'Ingresos hoy',
              value: '\$${dashboard.ingresos.toStringAsFixed(2)}',
              sub: 'Ventas del día',
              dotColor: dashboard.ingresos > 0
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFF59E0B),
            ),
            _IndicatorCard(
              label: 'Gastos hoy',
              value: '\$${dashboard.gastos.toStringAsFixed(2)}',
              sub: 'Compras registradas',
              dotColor: const Color(0xFF3B82F6),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('Últimos movimientos'),
            TextButton(
              onPressed: () => GoRouter.of(context).go('/products'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Ver todos',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (dashboard.ultimosMovimientos.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Sin movimientos registrados',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          for (final m in dashboard.ultimosMovimientos)
            _MovementCard(movement: m),
      ],
    );
  }
}

// ── Custom AppBar ─────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({
    required this.fecha,
    required this.negocioNombre,
    required this.dashAsync,
    required this.onProfileTap,
  });

  final String fecha;
  final String negocioNombre;
  final AsyncValue<DashboardData> dashAsync;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBrandNavy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fecha,
                          style: const TextStyle(
                            color: Color(0xAAFFFFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          negocioNombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kBrandAmber,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kBrandAmber.withValues(alpha: 0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, size: 22, color: kBrandNavy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SummaryBanner(dashAsync: dashAsync),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.dashAsync});

  final AsyncValue<DashboardData> dashAsync;

  @override
  Widget build(BuildContext context) {
    final (ingresos, gastos, utilidad) = dashAsync.when(
      data: (d) => (
        '\$${d.ingresos.toStringAsFixed(2)}',
        '\$${d.gastos.toStringAsFixed(2)}',
        '\$${d.utilidad.toStringAsFixed(2)}',
      ),
      loading: () => ('…', '…', '…'),
      error: (_, _) => ('\$0.00', '\$0.00', '\$0.00'),
    );

    final items = [
      ('Ingresos', ingresos, const Color(0xFF4ADE80)),
      ('Gastos', gastos, const Color(0xFFF87171)),
      ('Utilidad', utilidad, const Color(0xFFFCD34D)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      color: items[i].$3,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].$1,
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.2),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _kQuickActions.length; i++) ...[
          Expanded(child: _QuickActionCard(action: _kQuickActions[i])),
          if (i < _kQuickActions.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = action.color.withValues(alpha: isDark ? 0.15 : 0.12);

    return GestureDetector(
      onTap: () => context.go(action.route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
          border:
              isDark ? Border.all(color: cs.outlineVariant, width: 0.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, size: 22, color: action.color),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Movement card ─────────────────────────────────────────────────────────────

class _MovementCard extends StatelessWidget {
  const _MovementCard({required this.movement});

  final UltimoMovimiento movement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEntrada = movement.tipo == 'entrada';
    final color =
        isEntrada ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
        border:
            isDark ? Border.all(color: cs.outlineVariant, width: 0.5) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEntrada ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isEntrada ? 'Entrada' : 'Salida'} — ${movement.productoNombre}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  _formatTime(movement.creadoEn),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isEntrada ? '+' : '-'}${movement.cantidad}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    return DateFormat('d MMM', 'es').format(dt);
  }
}

// ── Skeleton card ─────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 10,
              width: 80,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 18,
              width: 60,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 10,
              width: 100,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.dotColor,
  });

  final String label;
  final String value;
  final String sub;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sub,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
