import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/features/auth/auth_provider.dart';
import 'package:ecua_inventario/features/suppliers/supplier_api_models.dart';
import 'package:ecua_inventario/features/suppliers/supplier_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  const SupplierDetailScreen({super.key, required this.supplierId});
  final String? supplierId;

  @override
  ConsumerState<SupplierDetailScreen> createState() =>
      _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;
  bool _initialized = false;
  String? _errorMessage;

  bool get _isNew =>
      widget.supplierId == null || widget.supplierId == 'new';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _populateFromDto(ProveedorDto s) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = s.nombre;
    _contactCtrl.text = s.contacto;
    _phoneCtrl.text = s.telefono;
    _emailCtrl.text = s.email;
    _addressCtrl.text = s.direccion;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(supplierRepositoryProvider);
      if (_isNew) {
        await repo.crear(
          nombre: _nameCtrl.text.trim(),
          contacto: _contactCtrl.text.trim(),
          telefono: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          direccion: _addressCtrl.text.trim(),
        );
      } else {
        await repo.actualizar(
          widget.supplierId!,
          nombre: _nameCtrl.text.trim(),
          contacto: _contactCtrl.text.trim(),
          telefono: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          direccion: _addressCtrl.text.trim(),
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

    if (!_isNew) {
      final supplierAsync = ref.watch(proveedorProvider(widget.supplierId!));
      supplierAsync.whenData(_populateFromDto);

      if (supplierAsync.isLoading && !_initialized) {
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
        title: Text(_isNew ? 'Nuevo proveedor' : 'Editar proveedor'),
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
                  labelText: 'Nombre del proveedor',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Persona de contacto',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && !v.contains('@')) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.location_on_outlined),
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
                child: _loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.onPrimary),
                      )
                    : Text(
                        _isNew ? 'Guardar proveedor' : 'Actualizar proveedor'),
              ),
            ],
          ),
        ),
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
