import 'package:facilito/app/theme/app_theme.dart';
import 'package:facilito/features/auth/auth_provider.dart';
import 'package:facilito/features/products/product_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _MovType { entrada, salida }

class MovementScreen extends ConsumerStatefulWidget {
  const MovementScreen({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends ConsumerState<MovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  _MovType _type = _MovType.entrada;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
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
      await repo.registrarMovimiento(
        productoId: widget.productId,
        tipo: _type == _MovType.entrada ? 'entrada' : 'salida',
        cantidad: double.parse(_qtyCtrl.text),
        nota: _noteCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movimiento registrado correctamente'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _errorMessage = AuthServiceX.dioError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final productAsync = ref.watch(productoProvider(widget.productId));

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
              productAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (product) => Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Icon(Icons.inventory_outlined, color: cs.primary),
                    ),
                    title: Text(product.nombre,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'Stock actual: ${product.stockActual} ${product.unidad}'),
                  ),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                decoration: InputDecoration(
                  labelText: productAsync.valueOrNull != null
                      ? 'Cantidad (${productAsync.valueOrNull!.unidad})'
                      : 'Cantidad',
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
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _type == _MovType.entrada
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                ),
                child: _loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.onPrimary),
                      )
                    : Text(
                        _type == _MovType.entrada
                            ? 'Registrar entrada'
                            : 'Registrar salida',
                      ),
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
