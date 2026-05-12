import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/features/suppliers/supplier_api_models.dart';
import 'package:ecua_inventario/features/suppliers/supplier_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProveedorDto> _applyFilter(List<ProveedorDto> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where((s) =>
            s.nombre.toLowerCase().contains(q) ||
            s.contacto.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suppliersAsync = ref.watch(proveedoresProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        foregroundColor: Colors.white,
        title: const Text('Proveedores'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/suppliers/new');
          ref.invalidate(proveedoresProvider);
        },
        backgroundColor: kBrandAmber,
        foregroundColor: kBrandNavy,
        tooltip: 'Agregar proveedor',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Buscar proveedor…',
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
          Expanded(
            child: suppliersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: 40, color: cs.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('Error al cargar proveedores',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => ref.invalidate(proveedoresProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (suppliers) {
                final filtered = _applyFilter(suppliers);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 48, color: cs.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('Sin resultados',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(proveedoresProvider.future),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        96 + MediaQuery.of(context).padding.bottom),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _SupplierTile(
                      supplier: filtered[i],
                      onTap: () async {
                        await context.push('/suppliers/${filtered[i].id}');
                        ref.invalidate(proveedoresProvider);
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

class _SupplierTile extends StatelessWidget {
  const _SupplierTile({required this.supplier, required this.onTap});
  final ProveedorDto supplier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.local_shipping_outlined,
              color: cs.primary, size: 20),
        ),
        title: Text(supplier.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(supplier.contacto,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      ),
    );
  }
}
