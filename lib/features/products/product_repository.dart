import 'package:dio/dio.dart';
import 'package:ecua_inventario/features/products/product_api_models.dart';

class ProductRepository {
  const ProductRepository(this._dio);

  final Dio _dio;

  Future<List<ProductoDto>> listar() async {
    final response = await _dio.get<List<dynamic>>('/api/inventario/productos/');
    return (response.data ?? [])
        .map((e) => ProductoDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductoDto> obtener(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/inventario/productos/$id/');
    return ProductoDto.fromJson(response.data!);
  }

  Future<ProductoDto> crear({
    required String nombre,
    required String categoria,
    required double costo,
    required String unidad,
    required double stockActual,
    required double stockMinimo,
    double? precioVenta,
    String? proveedorId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/inventario/productos/',
      data: {
        'nombre': nombre,
        'categoria': categoria,
        'costo': costo,
        'unidad': unidad,
        'stock_actual': stockActual,
        'stock_minimo': stockMinimo,
        if (precioVenta != null && precioVenta > 0) 'precio_venta': precioVenta,
        // ignore: use_null_aware_elements
        if (proveedorId != null) 'proveedor': proveedorId,
      },
    );
    return ProductoDto.fromJson(response.data!);
  }

  Future<ProductoDto> actualizar(
    String id, {
    required String nombre,
    required String categoria,
    required double costo,
    required String unidad,
    required double stockMinimo,
    double? precioVenta,
    String? proveedorId,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/inventario/productos/$id/',
      data: {
        'nombre': nombre,
        'categoria': categoria,
        'costo': costo,
        'unidad': unidad,
        'stock_minimo': stockMinimo,
        if (precioVenta != null && precioVenta > 0) 'precio_venta': precioVenta,
        'proveedor': proveedorId,
      },
    );
    return ProductoDto.fromJson(response.data!);
  }

  Future<void> eliminar(String id) async {
    await _dio.delete<void>('/api/inventario/productos/$id/');
  }

  Future<MovimientoDto> registrarMovimiento({
    required String productoId,
    required String tipo,
    required double cantidad,
    String motivo = '',
    String nota = '',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/inventario/productos/$productoId/movimiento/',
      data: {
        'tipo': tipo,
        'cantidad': cantidad,
        if (motivo.isNotEmpty) 'motivo': motivo,
        if (nota.isNotEmpty) 'nota': nota,
      },
    );
    return MovimientoDto.fromJson(response.data!);
  }
}
