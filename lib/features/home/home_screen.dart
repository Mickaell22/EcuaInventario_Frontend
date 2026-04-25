import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum _Semaforo { verde, amarillo, rojo }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fecha = DateFormat("EEEE, d 'de' MMMM", 'es').format(now);

    const indicadores = [
      (label: 'Utilidad del mes', valor: '\$0.00', sub: 'Ing \$0 · Gas \$0', estado: _Semaforo.amarillo),
      (label: 'Stock crítico', valor: '0 insumos', sub: 'Todo en orden', estado: _Semaforo.verde),
      (label: 'Margen promedio', valor: '0%', sub: 'Sin recetas aún', estado: _Semaforo.rojo),
      (label: 'Recetas activas', valor: '0', sub: 'Agrega tu primer plato', estado: _Semaforo.rojo),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(fecha: fecha),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResumenCard(),
                    const SizedBox(height: 16),
                    const _SectionLabel('Indicadores'),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.4,
                      children: indicadores
                          .map((ind) => _IndicadorCard(label: ind.label, valor: ind.valor, sub: ind.sub, estado: ind.estado))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const _SectionLabel('Últimos movimientos'),
                    const SizedBox(height: 8),
                    _MovimientosCard(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/chat'),
        backgroundColor: kBrandAmber,
        foregroundColor: kBrandNavy,
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.fecha});
  final String fecha;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBrandNavy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panel de salud',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: kBrandAmber, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('EcuaInventario',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(fecha,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: kBrandAmber.withValues(alpha: 0.15),
            child: const Icon(Icons.person_outline, color: kBrandAmber),
          ),
        ],
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            const _ResumenItem(label: 'Ingresos', valor: '\$0.00', color: Color(0xFF22C55E)),
            _Divider(),
            const _ResumenItem(label: 'Gastos', valor: '\$0.00', color: Color(0xFFEF4444)),
            _Divider(),
            const _ResumenItem(label: 'Utilidad', valor: '\$0.00', color: kBrandNavy),
          ],
        ),
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  const _ResumenItem({required this.label, required this.valor, required this.color});
  final String label;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(valor,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 32, width: 1, color: Colors.grey.shade200);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: Colors.grey, letterSpacing: 1.2, fontWeight: FontWeight.w600));
  }
}

class _IndicadorCard extends StatelessWidget {
  const _IndicadorCard({required this.label, required this.valor, required this.sub, required this.estado});
  final String label;
  final String valor;
  final String sub;
  final _Semaforo estado;

  Color get _dotColor {
    return switch (estado) {
      _Semaforo.verde => const Color(0xFF22C55E),
      _Semaforo.amarillo => const Color(0xFFF59E0B),
      _Semaforo.rojo => const Color(0xFFEF4444),
    };
  }

  @override
  Widget build(BuildContext context) {
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
                Container(width: 10, height: 10, decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            Text(valor,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            Text(sub,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _MovimientosCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 36),
              SizedBox(height: 8),
              Text('Sin movimientos aún', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
