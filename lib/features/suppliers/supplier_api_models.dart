class ProveedorDto {
  const ProveedorDto({
    required this.id,
    required this.nombre,
    required this.contacto,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.activo,
  });

  final String id;
  final String nombre;
  final String contacto;
  final String telefono;
  final String email;
  final String direccion;
  final bool activo;

  factory ProveedorDto.fromJson(Map<String, dynamic> j) => ProveedorDto(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        contacto: (j['contacto'] as String?) ?? '',
        telefono: (j['telefono'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        direccion: (j['direccion'] as String?) ?? '',
        activo: (j['activo'] as bool?) ?? true,
      );
}
