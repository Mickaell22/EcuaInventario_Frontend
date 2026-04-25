import 'package:ecua_inventario/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser, this.proposal});
  final String text;
  final bool isUser;
  final _Proposal? proposal;
}

class _Proposal {
  const _Proposal({required this.summary, required this.data});
  final String summary;
  final Map<String, String> data;
}

const _sugerencias = [
  '¿Cómo va mi negocio?',
  '¿Qué insumos están bajos?',
  '¿Receta más rentable?',
  '¿Cuánto gané este mes?',
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      text: '¡Hola! Soy tu asistente de EcuaInventario ✨\nPuedes enviarme un mensaje, grabar un audio o tomar una foto de una factura.',
      isUser: false,
    ),
  ];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      _sending = true;
    });
    _scrollToBottom();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _messages.add(
        const _ChatMessage(
          text: 'Entendido. Detecté el siguiente movimiento de inventario:',
          isUser: false,
          proposal: _Proposal(
            summary: 'Entrada de insumo',
            data: {
              'Producto': 'Aceite de oliva',
              'Cantidad': '5 litros',
              'Costo': '\$12.50',
              'Proveedor': 'Sin asignar',
            },
          ),
        ),
      );
      _sending = false;
    });
    _scrollToBottom();
  }

  void _confirmProposal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Movimiento registrado correctamente'),
        backgroundColor: kBrandNavy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _ChatHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _MessageBubble(
                message: _messages[i],
                onConfirm: _confirmProposal,
              ),
            ),
          ),
          if (_sending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kBrandAmber),
                  ),
                  const SizedBox(width: 8),
                  Text('Procesando...', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
          _SugerenciasBar(onTap: _sendMessage),
          _InputBar(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBrandNavy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: kBrandAmber, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome, size: 20, color: kBrandNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asistente IA',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('IA · Siempre disponible',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SugerenciasBar extends StatelessWidget {
  const _SugerenciasBar({required this.onTap});
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sugerencias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => onTap(_sugerencias[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(_sugerencias[i],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey.shade700)),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onConfirm});
  final _ChatMessage message;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: kBrandAmber,
                  child: Icon(Icons.auto_awesome, size: 14, color: kBrandNavy),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? kBrandNavy : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(color: isUser ? Colors.white : Colors.grey.shade800, fontSize: 14, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
          if (message.proposal != null) ...[
            const SizedBox(height: 8),
            _ProposalCard(proposal: message.proposal!, onConfirm: onConfirm),
          ],
        ],
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.proposal, required this.onConfirm});
  final _Proposal proposal;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
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
          Text(proposal.summary,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: kBrandNavy)),
          const SizedBox(height: 8),
          ...proposal.data.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Text('${e.key}: ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text(e.value, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(backgroundColor: kBrandNavy, minimumSize: const Size(0, 36)),
                  child: const Text('Confirmar', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
                  child: const Text('Editar', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.mic_outlined),
            onPressed: () {},
            color: Colors.grey,
            iconSize: 22,
          ),
          IconButton(
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: () {},
            color: Colors.grey,
            iconSize: 22,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onSend(controller.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: kBrandAmber, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, size: 18, color: kBrandNavy),
            ),
          ),
        ],
      ),
    );
  }
}
