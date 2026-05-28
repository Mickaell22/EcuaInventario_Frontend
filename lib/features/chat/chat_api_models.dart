class ChatRespuesta {
  const ChatRespuesta({
    required this.ok,
    required this.accion,
    required this.resumen,
    required this.datos,
  });

  final bool ok;
  final String accion;
  final String resumen;
  final Map<String, dynamic> datos;

  bool get esAccionable =>
      accion.isNotEmpty && accion != 'no_reconocido' && accion != 'responder';

  factory ChatRespuesta.fromJson(Map<String, dynamic> j) => ChatRespuesta(
        ok: (j['ok'] as bool?) ?? false,
        accion: (j['accion'] as String?) ?? '',
        resumen: (j['resumen'] as String?) ?? '',
        datos: (j['datos'] as Map<String, dynamic>?) ?? {},
      );
}

class ConfirmarRequest {
  const ConfirmarRequest({required this.accion, required this.datos});

  final String accion;
  final Map<String, dynamic> datos;

  Map<String, dynamic> toJson() => {'accion': accion, 'datos': datos};
}

class ConfirmarRespuesta {
  const ConfirmarRespuesta({required this.ok, required this.detalle});

  final bool ok;
  final String detalle;

  factory ConfirmarRespuesta.fromJson(Map<String, dynamic> j) =>
      ConfirmarRespuesta(
        ok: (j['ok'] as bool?) ?? false,
        detalle: (j['detalle'] as String?) ?? '',
      );
}
