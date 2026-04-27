import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/features/products/product_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MovementScreen extends StatefulWidget {
  const MovementScreen({super.key, required this.productId});
  final String productId;

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  _MovType _type = _MovType.entrada;
  bool _loading = false;

  MockProduct? get _product =>
      kMockProducts.where((p) => p.id == widget.productId).firstOrNull;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimiento registrado correctamente'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final product = _product;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        foregroundColor: Colors.white,
        title: const Text('Registrar movimiento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (product != null)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Icon(Icons.inventory_outlined, color: cs.primary),
                    ),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Stock actual: ${product.stock} ${product.unit}'),
                  ),
                ),
              const SizedBox(height: 24),
              const _Label('Tipo de movimiento'),
              const SizedBox(height: 8),
              SegmentedButton<_MovType>(
                segments: const [
                  ButtonSegment(
                    value: _MovType.entrada,
                    label: Text('Entrada'),
                    icon: Icon(Icons.add_circle_outline),
                  ),
                  ButtonSegment(
                    value: _MovType.salida,
                    label: Text('Salida'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                decoration: InputDecoration(
                  labelText: 'Cantidad${product != null ? ' (${product.unit})' : ''}',
                  prefixIcon: Icon(
                    _type == _MovType.entrada ? Icons.add : Icons.remove,
                    color: _type == _MovType.entrada
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa la cantidad';
                  final qty = double.tryParse(v);
                  if (qty == null || qty <= 0) return 'Cantidad inválida';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _type == _MovType.entrada ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                ),
                child: _loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                      )
                    : Text(
                        _type == _MovType.entrada ? 'Registrar entrada' : 'Registrar salida',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MovType { entrada, salida }

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
