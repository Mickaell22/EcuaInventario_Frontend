class UltimoMovimiento {
  const UltimoMovimiento({
    required this.id,
    required this.tipo,
    required this.motivo,
    required this.cantidad,
    required this.productoNombre,
    required this.creadoEn,
  });

  final String id;
  final String tipo;
  final String motivo;
  final String cantidad;
  final String productoNombre;
  final DateTime creadoEn;

  factory UltimoMovimiento.fromJson(Map<String, dynamic> j) => UltimoMovimiento(
        id: j['id'] as String,
        tipo: j['tipo'] as String,
        motivo: (j['motivo'] as String?) ?? '',
        cantidad: j['cantidad'].toString(),
        productoNombre: (j['producto_nombre'] as String?) ?? '',
        creadoEn: DateTime.parse(j['creado_en'] as String),
      );
}

class StockCritico {
  const StockCritico({required this.count});
  final int count;
}

class DashboardData {
  const DashboardData({
    required this.fecha,
    required this.ingresos,
    required this.gastos,
    required this.utilidad,
    required this.stockCriticoCount,
    required this.ultimosMovimientos,
  });

  final String fecha;
  final double ingresos;
  final double gastos;
  final double utilidad;
  final int stockCriticoCount;
  final List<UltimoMovimiento> ultimosMovimientos;

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        fecha: j['fecha'] as String,
        ingresos: double.parse(j['ingresos'].toString()),
        gastos: double.parse(j['gastos'].toString()),
        utilidad: double.parse(j['utilidad'].toString()),
        stockCriticoCount:
            (j['stock_critico'] as Map<String, dynamic>)['count'] as int,
        ultimosMovimientos: (j['ultimos_movimientos'] as List<dynamic>)
            .map((e) => UltimoMovimiento.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
