import 'package:dio/dio.dart';
import 'package:facilito/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Se incrementa cuando el refresh token expira y el usuario debe volver a login.
/// GoRouter escucha este notifier vía `refreshListenable`.
final sessionExpiredNotifier = ValueNotifier<int>(0);

class ApiClient {
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    _dio.interceptors.add(_AuthInterceptor(_dio, _storage));
  }

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Evitar bucle infinito en el retry marcando la petición como ya reintentada
    final alreadyRetried = err.requestOptions.extra['_retried'] == true;

    if (err.response?.statusCode == 401 && !alreadyRetried && !_isRefreshing) {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        _isRefreshing = true;
        try {
          // Dio aparte (sin _AuthInterceptor) para no reintentar en bucle,
          // pero con los mismos timeouts que el cliente principal.
          final refreshDio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            ),
          );
          final response = await refreshDio.post<Map<String, dynamic>>(
            '${AppConfig.baseUrl}/api/auth/token/refresh/',
            data: {'refresh': refreshToken},
          );
          final responseData = response.data!;
          final newAccess = responseData['access'] as String;
          final newRefresh = responseData['refresh'] as String?;

          await _storage.write(key: 'access_token', value: newAccess);
          if (newRefresh != null) {
            await _storage.write(key: 'refresh_token', value: newRefresh);
          }

          // Reintentar la petición original con el nuevo token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          err.requestOptions.extra['_retried'] = true;
          final retryResponse = await _dio.fetch<dynamic>(err.requestOptions);
          return handler.resolve(retryResponse);
        } on DioException catch (e) {
          // Solo cerrar sesión si el backend rechazó el refresh (4xx).
          // Un error de red o 5xx es transitorio: se conserva la sesión
          // y la petición original falla con su error normal.
          final code = e.response?.statusCode;
          if (code != null && code >= 400 && code < 500) {
            await _storage.deleteAll();
            sessionExpiredNotifier.value++;
          }
        } catch (_) {
          // Respuesta malformada del refresh: no cerrar sesión por eso.
        } finally {
          _isRefreshing = false;
        }
      } else {
        await _storage.deleteAll();
        sessionExpiredNotifier.value++;
      }
    }
    handler.next(err);
  }
}
