import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  _Indicator('Utilidad del mes', '\$0.00', 'Ing \$0 · Gas \$0', _Status.warn),
  _Indicator('Stock crítico', '0 insumos', 'Todo en orden', _Status.ok),
  _Indicator('Margen promedio', '0 %', 'Sin recetas', _Status.bad),
  _Indicator('Recetas activas', '0', 'Agrega tu primer plato', _Status.bad),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        foregroundColor: Colors.white,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('EcuaInventario',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(fecha,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.white54)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: CircleAvatar(
                backgroundColor: kBrandAmber.withValues(alpha: 0.2),
                child: const Icon(Icons.person_outline, color: kBrandAmber, size: 20),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/chat'),
        backgroundColor: kBrandAmber,
        foregroundColor: kBrandNavy,
        tooltip: 'Asistente IA',
        child: const Icon(Icons.auto_awesome),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const _SummaryCard(),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          const _SectionLabel('Últimos movimientos'),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 36),
                    const SizedBox(height: 8),
                    Text('Sin movimientos aún', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      ('Ingresos', '\$0.00', const Color(0xFF22C55E)),
      ('Gastos', '\$0.00', const Color(0xFFEF4444)),
      ('Utilidad', '\$0.00', cs.primary),
    ];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Text(items[i].$1,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(items[i].$2,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: items[i].$3,
                              fontWeight: FontWeight.bold,
                            )),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Container(height: 32, width: 1, color: cs.outlineVariant),
            ],
          ],
        ),
      ),
    );
  }
}

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
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: indicator.dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(indicator.label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            Text(indicator.value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
                overflow: TextOverflow.ellipsis),
            Text(indicator.sub,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
