import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _OnboardingPage {
  const _OnboardingPage({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _OnboardingPage(
    icon: Icons.inventory_2_outlined,
    title: 'Controla tu inventario',
    body: 'Registra insumos, productos y movimientos desde tu celular en segundos.',
  ),
  _OnboardingPage(
    icon: Icons.trending_up_outlined,
    title: 'Conoce tus márgenes',
    body: 'Calcula costos y precios de venta para que tu negocio siempre sea rentable.',
  ),
  _OnboardingPage(
    icon: Icons.chat_outlined,
    title: 'Habla con tu asistente IA',
    body: 'Registra datos enviando un audio, una foto o un mensaje de texto.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon, size: 96, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(page.body, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _current == i ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(onPressed: _next, child: Text(_current < _pages.length - 1 ? 'Siguiente' : 'Empezar')),
                  if (_current < _pages.length - 1)
                    TextButton(onPressed: () => context.go('/login'), child: const Text('Omitir')),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
