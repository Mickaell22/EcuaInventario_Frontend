import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ── Mock data ────────────────────────────────────────────────────────────────

class _Movement {
  const _Movement(this.icon, this.color, this.label, this.amount, this.time);
  final IconData icon;
  final Color color;
  final String label;
  final String amount;
  final String time;
}

const _kMovements = [
  _Movement(Icons.arrow_upward, Color(0xFF10B981), 'Entrada — Aceite de oliva',
      '+5 L', 'hace 30 min'),
  _Movement(Icons.arrow_downward, Color(0xFFEF4444), 'Salida — Harina',
      '-2 kg', 'hace 2 h'),
  _Movement(Icons.arrow_upward, Color(0xFF10B981), 'Entrada — Leche',
      '+10 L', 'ayer'),
];

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

enum _Status { ok, warn, bad }

class _Indicator {
  const _Indicator(this.label, this.value, this.sub, this.status);
  final String label;
  final String value;
  final String sub;
  final _Status status;

  Color get dotColor => switch (status) {
        _Status.ok => const Color(0xFF22C55E),
        _Status.warn => const Color(0xFFF59E0B),
        _Status.bad => const Color(0xFFEF4444),
      };
}

const _kIndicators = [
  _Indicator('Utilidad del mes', '\$0.00', 'Sin movimientos', _Status.warn),
  _Indicator('Stock crítico', '0 items', 'Todo en orden ✓', _Status.ok),
  _Indicator('Margen promedio', '— %', 'Sin recetas aún', _Status.bad),
  _Indicator('Platos activos', '0', 'Agrega tu primer plato', _Status.bad),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fecha =
        DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(165),
        child: _HomeAppBar(
          fecha: fecha,
          onProfileTap: () => context.push('/profile'),
        ),
      ),
      body: ListView(
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
              for (final ind in _kIndicators) _IndicatorCard(indicator: ind),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('Últimos movimientos'),
              TextButton(
                onPressed: () => context.go('/products'),
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
          for (final m in _kMovements) _MovementCard(movement: m),
        ],
      ),
    );
  }
}

// ── Custom AppBar with embedded summary ──────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({required this.fecha, required this.onProfileTap});

  final String fecha;
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
                        const Text(
                          'Cevichería El Pacífico',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
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
              const _SummaryBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner();

  static const _items = [
    ('Ingresos', '\$0.00', Color(0xFF4ADE80)),
    ('Gastos', '\$0.00', Color(0xFFF87171)),
    ('Utilidad', '\$0.00', Color(0xFFFCD34D)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _items.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _items[i].$2,
                    style: TextStyle(
                      color: _items[i].$3,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _items[i].$1,
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (i < _items.length - 1)
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
          border: isDark
              ? Border.all(color: cs.outlineVariant, width: 0.5)
              : null,
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

  final _Movement movement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        border: isDark
            ? Border.all(color: cs.outlineVariant, width: 0.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: movement.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(movement.icon, size: 18, color: movement.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  movement.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  movement.time,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            movement.amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: movement.color,
            ),
          ),
        ],
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
  const _IndicatorCard({required this.indicator});

  final _Indicator indicator;

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
                    color: indicator.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    indicator.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              indicator.value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              indicator.sub,
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
