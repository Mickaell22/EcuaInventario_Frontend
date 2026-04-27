import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/features/products/product_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  _Filter _filter = _Filter.todos;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MockProduct> get _filtered {
    final list = kMockProducts.where((p) {
      if (_filter == _Filter.insumos && p.category != ProductCategory.insumo) return false;
      if (_filter == _Filter.platos && p.category != ProductCategory.plato) return false;
      if (_query.isNotEmpty && !p.name.toLowerCase().contains(_query.toLowerCase())) return false;
      return true;
    }).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        foregroundColor: Colors.white,
        title: const Text('Inventario'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/new'),
        backgroundColor: kBrandAmber,
        foregroundColor: kBrandNavy,
        tooltip: 'Agregar producto',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Buscar producto o insumo…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: cs.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('Sin resultados', style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _ProductTile(
                      product: filtered[i],
                      onTap: () => context.push('/products/${filtered[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

enum _Filter {
  todos('Todos'),
  insumos('Insumos'),
  platos('Platos');

  const _Filter(this.label);
  final String label;
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});
  final MockProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stockStatus = product.stockStatus;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: product.category == ProductCategory.insumo
              ? cs.primaryContainer
              : kBrandAmber.withValues(alpha: 0.2),
          child: Icon(
            product.category == ProductCategory.insumo
                ? Icons.grain
                : Icons.restaurant_menu,
            color: product.category == ProductCategory.insumo ? cs.primary : kBrandAmber,
            size: 20,
          ),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${product.stock} ${product.unit}  ·  mín ${product.minStock} ${product.unit}',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: stockStatus.color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 4),
            Text(
              product.category == ProductCategory.plato
                  ? '\$${product.price.toStringAsFixed(2)}'
                  : '\$${product.cost.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
