import 'package:facilito/app/theme/app_theme.dart';
import 'package:facilito/features/auth/auth_provider.dart';
import 'package:facilito/features/home/dashboard_models.dart';
import 'package:facilito/features/home/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ── Quick actions (static) ────────────────────────────────────────────────────

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

const _kQuickActions = [
  _QuickAction(Icons.swap_vert, 'Movimiento', '/products'),
  _QuickAction(Icons.add_circle_outline, 'Producto', '/products/new'),
  _QuickAction(Icons.local_shipping_outlined, 'Proveedor', '/suppliers'),
  _QuickAction(Icons.auto_awesome, 'Asistente', '/chat'),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fecha,
              style: const TextStyle(
                color: Color(0xAAFFFFFF),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              negocio?.nombre ?? usuario?.nombre ?? 'Mi negocio',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: kBrandAmber,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 20, color: kBrandNavy),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: dashAsync.when(
          loading: () => _buildBody(
            context: context,
            bottomPad: bottomPad,
            dashboard: null,
            loading: true,
          ),
          error: (e, _) => _buildBody(
            context: context,
            bottomPad: bottomPad,
            dashboard: null,
            loading: false,
            error: true,
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (d) => _buildBody(
            context: context,
            bottomPad: bottomPad,
            dashboard: d,
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required double bottomPad,
    required DashboardData? dashboard,
    bool loading = false,
    bool error = false,
    VoidCallback? onRetry,
  }) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 96 + bottomPad),
      children: [
        const _SectionLabel('Acciones rápidas'),
        const SizedBox(height: 10),
        const _QuickActionsGrid(),
        const SizedBox(height: 24),
        const _SectionLabel('Resumen de hoy'),
        const SizedBox(height: 10),
        _ResumenCard(dashboard: dashboard, loading: loading),
        if (error) ...[
          const SizedBox(height: 12),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 6),
                Text('No se pudo cargar el resumen',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
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
              child: const Text('Ver todos',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (dashboard != null && dashboard.ultimosMovimientos.isEmpty)
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
        else if (dashboard != null)
          for (final m in dashboard.ultimosMovimientos)
            _MovementRow(movement: m),
      ],
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
          if (i < _kQuickActions.length - 1) const SizedBox(width: 8),
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

    return GestureDetector(
      onTap: () => context.go(action.route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon,
                size: 26,
                color: isDark ? cs.onSurface : kBrandNavy),
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

// ── Resumen del día ────────────────────────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({required this.dashboard, required this.loading});

  final DashboardData? dashboard;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String valMoney(double? v) =>
        loading ? '…' : '\$${(v ?? 0).toStringAsFixed(2)}';

    final rows = <(IconData, String, String)>[
      (Icons.arrow_upward, 'Ingresos hoy', valMoney(dashboard?.ingresos)),
      (Icons.arrow_downward, 'Gastos hoy', valMoney(dashboard?.gastos)),
      (
        Icons.account_balance_wallet_outlined,
        'Utilidad del día',
        valMoney(dashboard?.utilidad)
      ),
      (
        Icons.inventory_2_outlined,
        'Stock crítico',
        loading ? '…' : '${dashboard?.stockCriticoCount ?? 0} productos',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant, width: 0.8),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].$3,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Divider(
                height: 1,
                thickness: 0.8,
                indent: 16,
                endIndent: 16,
                color: cs.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

// ── Movement row ──────────────────────────────────────────────────────────────

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final UltimoMovimiento movement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEntrada = movement.tipo == 'entrada';

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEntrada ? Icons.add : Icons.remove,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  movement.productoNombre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${isEntrada ? 'Entrada' : 'Salida'}  ·  ${_formatTime(movement.creadoEn)}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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
              color: cs.onSurface,
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
