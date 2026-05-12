import 'package:dio/dio.dart';
import 'package:ecua_inventario/core/api/api_client_provider.dart';
import 'package:ecua_inventario/features/auth/auth_models.dart';
import 'package:ecua_inventario/features/auth/auth_service.dart';
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
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        // Try common error keys from DRF
        for (final key in ['detail', 'non_field_errors', 'email', 'password', 'error']) {
          final val = data[key];
          if (val is String) return val;
          if (val is List && val.isNotEmpty) return val.first.toString();
        }
        // Fallback: first value in the map
        final first = data.values.first;
        if (first is String) return first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Sin conexión con el servidor. Verifica tu red.';
      }
    }
    return 'Ocurrió un error inesperado.';
  }
}
