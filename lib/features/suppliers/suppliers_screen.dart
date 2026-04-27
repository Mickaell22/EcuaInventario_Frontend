import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/features/suppliers/supplier_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MockSupplier> get _filtered {
    if (_query.isEmpty) return kMockSuppliers;
    return kMockSuppliers
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()) ||
            s.contact.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        foregroundColor: Colors.white,
        title: const Text('Proveedores'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/suppliers/new'),
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
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 48, color: cs.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('Sin resultados', style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _SupplierTile(
                      supplier: filtered[i],
                      onTap: () => context.push('/suppliers/${filtered[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  const _SupplierTile({required this.supplier, required this.onTap});
  final MockSupplier supplier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.local_shipping_outlined, color: cs.primary, size: 20),
        ),
        title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(supplier.contact, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      ),
    );
  }
}
