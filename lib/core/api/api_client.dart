import 'package:dio/dio.dart';
import 'package:ecua_inventario/core/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient() {
    _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl, connectTimeout: const Duration(seconds: 10)));
    _dio.interceptors.add(_AuthInterceptor(_storage));
  }

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
