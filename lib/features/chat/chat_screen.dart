import 'package:facilito/app/theme/app_theme.dart';
import 'package:facilito/features/auth/auth_provider.dart';
import 'package:facilito/features/chat/chat_api_models.dart';
import 'package:facilito/features/chat/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Message model ─────────────────────────────────────────────────────────────

class _Message {
  _Message({required this.text, required this.isUser, this.respuesta});
  final String text;
  final bool isUser;
  final ChatRespuesta? respuesta;
}

const _kSuggestions = [
  '¿Cómo va mi negocio?',
  '¿Qué insumos están bajos?',
  '¿Receta más rentable?',
  '¿Cuánto gané este mes?',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messages = <_Message>[
    _Message(
      text: '¡Hola! Soy tu asistente de Facilito ✨\n'
          'Envíame un mensaje, graba un audio o toma una foto de factura.',
      isUser: false,
    ),
  ];
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;
  // Guard against double-tapping Confirmar
  bool _confirming = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _messages.add(_Message(text: text.trim(), isUser: true));
      _busy = true;
    });
    _scrollDown();
    try {
      final service = ref.read(chatServiceProvider);
      final respuesta = await service.enviarMensaje(text.trim());
      if (!mounted) return;
      setState(() {
        _messages.add(_Message(
          text: respuesta.esAccionable
              ? 'Entendido. Aquí tienes lo que detecté:'
              : respuesta.resumen,
          isUser: false,
          respuesta: respuesta.esAccionable ? respuesta : null,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Message(
          text: 'No pude procesar tu mensaje. Verifica tu conexión e intenta nuevamente.',
          isUser: false,
        ));
      });
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollDown();
    }
  }

  Future<void> _confirm(ChatRespuesta respuesta) async {
    if (_confirming) return;
    setState(() => _confirming = true);
    try {
      final service = ref.read(chatServiceProvider);
      final result = await service.confirmar(
        ConfirmarRequest(accion: respuesta.accion, datos: respuesta.datos),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.detalle.isNotEmpty
              ? result.detalle
              : 'Acción confirmada correctamente'),
          backgroundColor: kBrandNavy,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthServiceX.dioError(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrandNavy,
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration:
                  const BoxDecoration(color: kBrandAmber, shape: BoxShape.circle),
              child:
                  const Icon(Icons.auto_awesome, size: 18, color: kBrandNavy),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Asistente IA',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text('Siempre disponible',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _MessageBubble(
                message: _messages[i],
                confirming: _confirming,
                onConfirm: _confirm,
              ),
            ),
          ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: kBrandAmber),
                  ),
                  const SizedBox(width: 8),
                  Text('Procesando…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ],
              ),
            ),
          _SuggestionsBar(onTap: _send),
          _InputBar(controller: _controller, busy: _busy, onSend: _send),
        ],
      ),
    );
  }
}

// ── Suggestions bar ───────────────────────────────────────────────────────────

class _SuggestionsBar extends StatelessWidget {
  const _SuggestionsBar({required this.onTap});
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kSuggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => onTap(_kSuggestions[i]),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Text(_kSuggestions[i],
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.confirming,
    required this.onConfirm,
  });
  final _Message message;
  final bool confirming;
  final Future<void> Function(ChatRespuesta) onConfirm;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: kBrandAmber,
                  child:
                      Icon(Icons.auto_awesome, size: 14, color: kBrandNavy),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? kBrandNavy
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isUser ? 16 : 4),
                      bottomRight:
                          Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : cs.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (message.respuesta != null) ...[
            const SizedBox(height: 8),
            _ProposalCard(
              respuesta: message.respuesta!,
              confirming: confirming,
              onConfirm: onConfirm,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Proposal card ─────────────────────────────────────────────────────────────

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.respuesta,
    required this.confirming,
    required this.onConfirm,
  });
  final ChatRespuesta respuesta;
  final bool confirming;
  final Future<void> Function(ChatRespuesta) onConfirm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final displayFields = Map<String, String>.fromEntries(
      respuesta.datos.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .map((e) => MapEntry(
              _labelFor(e.key), e.value.toString())),
    );

    return Container(
      margin: const EdgeInsets.only(left: 36),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBrandAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBrandAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleFor(respuesta.accion),
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(
                    fontWeight: FontWeight.bold, color: cs.primary),
          ),
          if (respuesta.resumen.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(respuesta.resumen,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 8),
          for (final e in displayFields.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Text('${e.key}: ',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Text(e.value,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: confirming ? null : () => onConfirm(respuesta),
                  style: FilledButton.styleFrom(
                      backgroundColor: kBrandNavy,
                      minimumSize: const Size(0, 36)),
                  child: confirming
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirmar',
                          style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36)),
                  child: const Text('Editar',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _titleFor(String accion) => switch (accion) {
        'registrar_movimiento' => 'Movimiento de inventario',
        'crear_producto' => 'Nuevo producto',
        'crear_proveedor' => 'Nuevo proveedor',
        'actualizar_producto' => 'Actualización de producto',
        'registrar_venta' => 'Venta',
        _ => 'Acción propuesta',
      };

  String _labelFor(String key) => switch (key) {
        'producto' => 'Producto',
        'tipo' => 'Tipo',
        'cantidad' => 'Cantidad',
        'motivo' => 'Motivo',
        'nota' => 'Nota',
        'nombre' => 'Nombre',
        'categoria' => 'Categoría',
        'costo' => 'Costo',
        'unidad' => 'Unidad',
        'precio_venta' => 'Precio de venta',
        'proveedor' => 'Proveedor',
        'telefono' => 'Teléfono',
        'email' => 'Email',
        'detalles' => 'Detalles',
        _ => key,
      };
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.busy,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool busy;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.mic_outlined),
            onPressed: () {},
            color: cs.onSurfaceVariant,
            iconSize: 22,
          ),
          IconButton(
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: () {},
            color: cs.onSurfaceVariant,
            iconSize: 22,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                enabled: !busy,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: busy ? null : () => onSend(controller.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: busy
                    ? cs.onSurface.withValues(alpha: 0.12)
                    : kBrandAmber,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded,
                  size: 18,
                  color: busy ? cs.onSurfaceVariant : kBrandNavy),
            ),
          ),
        ],
      ),
    );
  }
}
