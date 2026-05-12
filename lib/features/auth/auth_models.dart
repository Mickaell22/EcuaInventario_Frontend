class UsuarioDto {
  const UsuarioDto({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
  });

  final String id;
  final String email;
  final String nombre;
  final String apellido;

  factory UsuarioDto.fromJson(Map<String, dynamic> j) => UsuarioDto(
        id: j['id'] as String,
        email: j['email'] as String,
        nombre: j['nombre'] as String,
        apellido: (j['apellido'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nombre': nombre,
        'apellido': apellido,
      };

  String get nombreCompleto => apellido.isEmpty ? nombre : '$nombre $apellido';
}

class NegocioDto {
  const NegocioDto({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.seedColor,
  });

  final String id;
  final String nombre;
  final String tipo;
  final String seedColor;

  factory NegocioDto.fromJson(Map<String, dynamic> j) => NegocioDto(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        tipo: (j['tipo'] as String?) ?? '',
        seedColor: (j['seed_color'] as String?) ?? '#1976D2',
      );
}

class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;
}
