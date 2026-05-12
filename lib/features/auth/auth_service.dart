import 'package:dio/dio.dart';
import 'package:ecua_inventario/features/auth/auth_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  AuthService(this._dio) : _storage = const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<({UsuarioDto usuario, NegocioDto? negocio})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login/',
      data: {'email': email, 'password': password},
    );
    final data = response.data!;
    await _saveTokens(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    final usuario = UsuarioDto.fromJson(data['usuario'] as Map<String, dynamic>);
    final negocio = data['negocio'] != null
        ? NegocioDto.fromJson(data['negocio'] as Map<String, dynamic>)
        : null;
    return (usuario: usuario, negocio: negocio);
  }

  Future<({UsuarioDto usuario})> registro({
    required String negocioNombre,
    required String negocioTipo,
    required String negocioSeedColor,
    required String nombre,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/registro/',
      data: {
        'negocio_nombre': negocioNombre,
        'negocio_tipo': negocioTipo,
        'negocio_seed_color': negocioSeedColor,
        'nombre': nombre,
        'email': email,
        'password': password,
      },
    );
    final data = response.data!;
    await _saveTokens(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    final usuario = UsuarioDto.fromJson(data['usuario'] as Map<String, dynamic>);
    return (usuario: usuario);
  }

  Future<UsuarioDto> perfil() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/auth/perfil/');
    return UsuarioDto.fromJson(response.data!);
  }

  Future<UsuarioDto> actualizarPerfil({
    required String nombre,
    required String apellido,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/auth/perfil/',
      data: {'nombre': nombre, 'apellido': apellido},
    );
    return UsuarioDto.fromJson(response.data!);
  }

  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/auth/cambiar-password/',
      data: {
        'password_actual': passwordActual,
        'password_nuevo': passwordNuevo,
      },
    );
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<void> _saveTokens({
    required String access,
    required String refresh,
  }) async {
    await Future.wait([
      _storage.write(key: 'access_token', value: access),
      _storage.write(key: 'refresh_token', value: refresh),
    ]);
  }
}
