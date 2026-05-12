import 'package:flutter/material.dart';

enum ProductCategory { insumo, plato }

enum StockStatus {
  ok(Color(0xFF22C55E)),
  warn(Color(0xFFF59E0B)),
  bad(Color(0xFFEF4444));

  const StockStatus(this.color);
  final Color color;
}

class ProductoDto {
  const ProductoDto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precioVenta,
    required this.costo,
    required this.stockActual,
    required this.unidad,
    required this.stockMinimo,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.stockBajo,
    required this.activo,
  });

  final String id;
  final String nombre;
  final ProductCategory categoria;
  final double precioVenta;
  final double costo;
  final double stockActual;
  final String unidad;
  final double stockMinimo;
  final String? proveedorId;
  final String? proveedorNombre;
  final bool stockBajo;
  final bool activo;

  factory ProductoDto.fromJson(Map<String, dynamic> j) => ProductoDto(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        categoria: j['categoria'] == 'plato' ? ProductCategory.plato : ProductCategory.insumo,
        precioVenta: double.parse((j['precio_venta'] ?? '0').toString()),
        costo: double.parse((j['costo'] ?? '0').toString()),
        stockActual: double.parse((j['stock_actual'] ?? '0').toString()),
        unidad: (j['unidad'] as String?) ?? 'unid',
        stockMinimo: double.parse((j['stock_minimo'] ?? '0').toString()),
        proveedorId: j['proveedor']?.toString(),
        proveedorNombre: j['proveedor_nombre'] as String?,
        stockBajo: (j['stock_bajo'] as bool?) ?? false,
        activo: (j['activo'] as bool?) ?? true,
      );

  StockStatus get stockStatus {
    if (stockActual <= 0) return StockStatus.bad;
    if (stockBajo) return StockStatus.warn;
    return StockStatus.ok;
  }

  double get margin =>
      precioVenta > 0 ? ((precioVenta - costo) / precioVenta) * 100 : 0;
}

class MovimientoDto {
  const MovimientoDto({
    required this.id,
    required this.tipo,
    required this.motivo,
    required this.cantidad,
    required this.nota,
    required this.productoNombre,
    required this.creadoEn,
  });

  final String id;
  final String tipo;
  final String motivo;
  final String cantidad;
  final String nota;
  final String productoNombre;
  final DateTime creadoEn;

  factory MovimientoDto.fromJson(Map<String, dynamic> j) => MovimientoDto(
        id: j['id'] as String,
        tipo: j['tipo'] as String,
        motivo: (j['motivo'] as String?) ?? '',
        cantidad: j['cantidad'].toString(),
        nota: (j['nota'] as String?) ?? '',
        productoNombre: (j['producto_nombre'] as String?) ?? '',
        creadoEn: DateTime.parse(j['creado_en'] as String),
      );
}
