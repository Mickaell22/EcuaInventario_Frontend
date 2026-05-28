import 'package:dio/dio.dart';
import 'package:facilito/core/api/api_client_provider.dart';
import 'package:facilito/features/auth/auth_models.dart';
import 'package:facilito/features/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return AuthService(dio);
});

// Cached negocio — set after login/registro, loaded lazily from perfil endpoint
final negocioProvider = StateProvider<NegocioDto?>((ref) => null);

// Cached usuario — updated after login/registro/perfil patch
final usuarioProvider = StateProvider<UsuarioDto?>((ref) => null);

// Extension helpers used by screens
extension AuthServiceX on AuthService {
  static String dioError(Object e) {
    if (e is! DioException) {
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }

    // 1. Mensaje de negocio/validación devuelto por el backend (DRF)
    final data = e.response?.data;
    if (data is Map && data.isNotEmpty) {
      for (final key in ['detail', 'non_field_errors', 'email', 'password', 'error']) {
        final val = data[key];
        if (val is String) return val;
        if (val is List && val.isNotEmpty) return val.first.toString();
      }
      final first = data.values.first;
      if (first is String) return first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }

    // 2. Respuesta del servidor sin cuerpo legible (error HTTP)
    final status = e.response?.statusCode;
    if (status != null) {
      if (status >= 500) {
        return 'El servidor no está disponible en este momento. Intenta de nuevo en unos minutos.';
      }
      if (status == 401 || status == 403) {
        return 'Correo o contraseña incorrectos.';
      }
      return 'No se pudo completar la solicitud (error $status).';
    }

    // 3. No hubo respuesta: problema de conexión
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'El servidor tardó demasiado en responder. Revisa tu conexión e intenta de nuevo.';
      case DioExceptionType.connectionError:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return 'No se pudo conectar con el servidor. Revisa tu conexión a internet.';
      case DioExceptionType.badCertificate:
        return 'No se pudo verificar la seguridad de la conexión.';
      case DioExceptionType.cancel:
        return 'La solicitud fue cancelada.';
    }
  }
}
