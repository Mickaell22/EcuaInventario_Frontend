import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/features/auth/auth_provider.dart';
import 'package:ecua_inventario/features/products/product_api_models.dart';
import 'package:ecua_inventario/features/products/product_providers.dart';
import 'package:ecua_inventario/features/suppliers/supplier_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String? productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  ProductCategory _category = ProductCategory.insumo;
  String _unit = 'kg';
  String? _supplierId;
  bool _loading = false;
  bool _initialized = false;
  String? _errorMessage;

  bool get _isNew =>
      widget.productId == null || widget.productId == 'new';

  double get _margin {
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (price <= 0) return 0;
    return ((price - cost) / price) * 100;
  }

  void _populateFromDto(ProductoDto p) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = p.nombre;
    _costCtrl.text = p.costo.toStringAsFixed(2);
    _priceCtrl.text = p.precioVenta > 0 ? p.precioVenta.toStringAsFixed(2) : '';
    _stockCtrl.text = p.stockActual.toStringAsFixed(
        p.stockActual == p.stockActual.truncateToDouble() ? 0 : 2);
    _minStockCtrl.text = p.stockMinimo.toStringAsFixed(
        p.stockMinimo == p.stockMinimo.truncateToDouble() ? 0 : 2);
    _category = p.categoria;
    _unit = p.unidad;
    _supplierId = p.proveedorId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(productRepositoryProvider);
      if (_isNew) {
        await repo.crear(
          nombre: _nameCtrl.text.trim(),
          categoria: _category == ProductCategory.insumo ? 'insumo' : 'plato',
          costo: double.parse(_costCtrl.text),
          unidad: _unit,
          stockActual: double.tryParse(_stockCtrl.text) ?? 0,
          stockMinimo: double.tryParse(_minStockCtrl.text) ?? 0,
          precioVenta: double.tryParse(_priceCtrl.text),
          proveedorId: _supplierId,
        );
      } else {
        await repo.actualizar(
          widget.productId!,
          nombre: _nameCtrl.text.trim(),
          categoria: _category == ProductCategory.insumo ? 'insumo' : 'plato',
          costo: double.parse(_costCtrl.text),
          unidad: _unit,
          stockMinimo: double.tryParse(_minStockCtrl.text) ?? 0,
          precioVenta: double.tryParse(_priceCtrl.text),
          proveedorId: _supplierId,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _errorMessage = AuthServiceX.dioError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suppliersAsync = ref.watch(proveedoresProvider);

    // For existing products: watch the provider and populate the form
    if (!_isNew) {
      final productAsync = ref.watch(productoProvider(widget.productId!));
      productAsync.whenData(_populateFromDto);

      if (productAsync.isLoading && !_initialized) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kBrandNavy,
            foregroundColor: Colors.white,
            title: const Text('Cargando…'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        foregroundColor: Colors.white,
        title: Text(_isNew ? 'Nuevo producto' : 'Editar producto'),
        actions: [
          if (!_isNew)
            TextButton.icon(
              onPressed: () =>
                  context.push('/products/${widget.productId}/move'),
              icon: const Icon(Icons.swap_vert, color: kBrandAmber),
              label: const Text('Movimiento',
                  style: TextStyle(color: kBrandAmber)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.label_outline)),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 20),
              const _Label('Categoría'),
              const SizedBox(height: 8),
              SegmentedButton<ProductCategory>(
                segments: const [
                  ButtonSegment(
                      value: ProductCategory.insumo,
                      label: Text('Insumo'),
                      icon: Icon(Icons.grain)),
                  ButtonSegment(
                      value: ProductCategory.plato,
                      label: Text('Plato'),
                      icon: Icon(Icons.restaurant_menu)),
                ],
                selected: {_category},
                onSelectionChanged: (s) =>
                    setState(() => _category = s.first),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'))
                      ],
                      decoration: const InputDecoration(
                          labelText: 'Costo (\$)',
                          prefixIcon: Icon(Icons.attach_money)),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'))
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Precio (\$)',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: _category == ProductCategory.plato
                          ? (v) => (v == null || v.isEmpty)
                              ? 'Requerido para platos'
                              : null
                          : null,
                    ),
                  ),
                ],
              ),
              if (_category == ProductCategory.plato) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Margen: ${_margin.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _margin >= 40
                                ? const Color(0xFF22C55E)
                                : _margin >= 20
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'))
                      ],
                      decoration: const InputDecoration(
                          labelText: 'Stock actual',
                          prefixIcon: Icon(Icons.inventory_outlined)),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _minStockCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'))
                      ],
                      decoration: const InputDecoration(
                          labelText: 'Stock mínimo',
                          prefixIcon:
                              Icon(Icons.warning_amber_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _Label('Unidad de medida'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final u in [
                    'kg',
                    'g',
                    'L',
                    'mL',
                    'unid',
                    'caja',
                    'porción'
                  ])
                    FilterChip(
                      label: Text(u),
                      selected: _unit == u,
                      onSelected: (_) => setState(() => _unit = u),
                    ),
                ],
              ),
              if (_category == ProductCategory.insumo) ...[
                const SizedBox(height: 20),
                const _Label('Proveedor'),
                const SizedBox(height: 8),
                suppliersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (suppliers) => DropdownButtonFormField<String>(
                    initialValue: _supplierId,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.local_shipping_outlined)),
                    hint: const Text('Seleccionar proveedor'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Sin proveedor')),
                      for (final s in suppliers)
                        DropdownMenuItem(value: s.id, child: Text(s.nombre)),
                    ],
                    onChanged: (v) => setState(() => _supplierId = v),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.onPrimary),
                      )
                    : Text(_isNew ? 'Guardar producto' : 'Actualizar producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: cs.onErrorContainer, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
