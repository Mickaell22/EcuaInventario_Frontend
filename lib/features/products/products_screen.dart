import 'package:facilito/app/theme/app_theme.dart';
import 'package:facilito/features/products/product_api_models.dart';
import 'package:facilito/features/products/product_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _Filter {
  todos('Todos'),
  insumos('Insumos'),
  platos('Platos');

  const _Filter(this.label);
  final String label;
}

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  _Filter _filter = _Filter.todos;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductoDto> _applyFilter(List<ProductoDto> list) {
    return list.where((p) {
      if (_filter == _Filter.insumos && p.categoria != ProductCategory.insumo) {
        return false;
      }
      if (_filter == _Filter.platos && p.categoria != ProductCategory.plato) {
        return false;
      }
      if (_query.isNotEmpty &&
          !p.nombre.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final productosAsync = ref.watch(productosProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        foregroundColor: Colors.white,
        title: const Text('Inventario'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/products/new');
          ref.invalidate(productosProvider);
        },
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
            child: productosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: 40, color: cs.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('Error al cargar productos',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => ref.invalidate(productosProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (productos) {
                final filtered = _applyFilter(productos);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: cs.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('Sin resultados',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(productosProvider.future),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        16, 8, 16, 96 + MediaQuery.of(context).padding.bottom),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _ProductTile(
                      product: filtered[i],
                      onTap: () async {
                        await context.push('/products/${filtered[i].id}');
                        ref.invalidate(productosProvider);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});
  final ProductoDto product;
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
          backgroundColor: product.categoria == ProductCategory.insumo
              ? cs.primaryContainer
              : kBrandAmber.withValues(alpha: 0.2),
          child: Icon(
            product.categoria == ProductCategory.insumo
                ? Icons.grain
                : Icons.restaurant_menu,
            color: product.categoria == ProductCategory.insumo
                ? cs.primary
                : kBrandAmber,
            size: 20,
          ),
        ),
        title: Text(product.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${product.stockActual} ${product.unidad}  ·  mín ${product.stockMinimo} ${product.unidad}',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: stockStatus.color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 4),
            Text(
              product.categoria == ProductCategory.plato
                  ? '\$${product.precioVenta.toStringAsFixed(2)}'
                  : '\$${product.costo.toStringAsFixed(2)}',
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
