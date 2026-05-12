import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:ecua_inventario/features/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _currentPassCtrl;
  late final TextEditingController _newPassCtrl;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _loading = false;
  bool _showChangePassword = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final usuario = ref.read(usuarioProvider);
    _nameCtrl = TextEditingController(text: usuario?.nombre ?? '');
    _currentPassCtrl = TextEditingController();
    _newPassCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final service = ref.read(authServiceProvider);

      if (_showChangePassword &&
          _currentPassCtrl.text.isNotEmpty &&
          _newPassCtrl.text.isNotEmpty) {
        // Change password — this blacklists all tokens; route guard will send to login
        await service.cambiarPassword(
          passwordActual: _currentPassCtrl.text,
          passwordNuevo: _newPassCtrl.text,
        );
        await service.logout();
        if (mounted) context.go('/login');
        return;
      }

      // Update profile name
      final updated = await service.actualizarPerfil(
        nombre: _nameCtrl.text.trim(),
        apellido: '',
      );
      ref.read(usuarioProvider.notifier).state = updated;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = AuthServiceX.dioError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: kBrandNavy),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authServiceProvider).logout();
    ref.read(usuarioProvider.notifier).state = null;
    ref.read(negocioProvider.notifier).state = null;
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final usuario = ref.watch(usuarioProvider);
    final negocio = ref.watch(negocioProvider);
    final displayName = usuario?.nombre ?? _nameCtrl.text;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        foregroundColor: Colors.white,
        title: const Text('Mi perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: kBrandNavy,
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: kBrandAmber,
                        child:
                            Icon(Icons.edit, size: 14, color: kBrandNavy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Datos personales',
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline)),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresa tu nombre'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: usuario?.email ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  if (negocio != null) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: negocio.nombre,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del negocio',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Seguridad',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cambiar contraseña'),
                    leading: const Icon(Icons.lock_outlined),
                    trailing: Icon(
                      _showChangePassword
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () => setState(
                        () => _showChangePassword = !_showChangePassword),
                  ),
                  if (_showChangePassword) ...[
                    TextFormField(
                      controller: _currentPassCtrl,
                      obscureText: _obscureCurrent,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Contraseña actual',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      validator: _showChangePassword
                          ? (v) => (v == null || v.length < 8)
                              ? 'Mínimo 8 caracteres'
                              : null
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPassCtrl,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: _showChangePassword
                          ? (v) => (v == null || v.length < 8)
                              ? 'Mínimo 8 caracteres'
                              : null
                          : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
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
                    : const Text('Guardar cambios'),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final errorColor =
                      Theme.of(context).colorScheme.error;
                  return OutlinedButton.icon(
                    onPressed: _logout,
                    icon: Icon(Icons.logout, color: errorColor),
                    label: Text('Cerrar sesión',
                        style: TextStyle(color: errorColor)),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: errorColor)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: kBrandAmber,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
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
                style: TextStyle(
                    color: cs.onErrorContainer, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
