import 'package:dio/dio.dart';
import 'package:facilito/features/suppliers/supplier_api_models.dart';

class SupplierRepository {
  const SupplierRepository(this._dio);

  final Dio _dio;

  Future<List<ProveedorDto>> listar() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/proveedores/');
    final results = (response.data?['results'] as List<dynamic>?) ?? [];
    return results
        .map((e) => ProveedorDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProveedorDto> obtener(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/proveedores/$id/');
    return ProveedorDto.fromJson(response.data!);
  }

  Future<ProveedorDto> crear({
    required String nombre,
    String contacto = '',
    String telefono = '',
    String email = '',
    String direccion = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/proveedores/',
      data: {
        'nombre': nombre,
        'contacto': contacto,
        'telefono': telefono,
        'email': email,
        'direccion': direccion,
      },
    );
    return ProveedorDto.fromJson(response.data!);
  }

  Future<ProveedorDto> actualizar(
    String id, {
    required String nombre,
    String contacto = '',
    String telefono = '',
    String email = '',
    String direccion = '',
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/proveedores/$id/',
      data: {
        'nombre': nombre,
        'contacto': contacto,
        'telefono': telefono,
        'email': email,
        'direccion': direccion,
      },
    );
    return ProveedorDto.fromJson(response.data!);
  }

  Future<void> eliminar(String id) async {
    await _dio.delete<void>('/api/proveedores/$id/');
  }
}
