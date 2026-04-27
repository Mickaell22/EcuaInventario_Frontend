import 'package:flutter/material.dart';

enum ProductCategory { insumo, plato }

enum StockStatus {
  ok(Color(0xFF22C55E)),
  warn(Color(0xFFF59E0B)),
  bad(Color(0xFFEF4444));

  const StockStatus(this.color);
  final Color color;
}

class MockProduct {
  const MockProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.stock,
    required this.minStock,
    required this.cost,
    required this.price,
    required this.supplierId,
  });

  final String id;
  final String name;
  final ProductCategory category;
  final String unit;
  final double stock;
  final double minStock;
  final double cost;
  final double price;
  final String supplierId;

  StockStatus get stockStatus {
    if (stock <= 0) return StockStatus.bad;
    if (stock <= minStock) return StockStatus.warn;
    return StockStatus.ok;
  }

  double get margin => price > 0 ? ((price - cost) / price) * 100 : 0;
}

const kMockProducts = [
  MockProduct(id: '1', name: 'Arroz', category: ProductCategory.insumo, unit: 'kg', stock: 45, minStock: 10, cost: 0.80, price: 0, supplierId: '1'),
  MockProduct(id: '2', name: 'Aceite vegetal', category: ProductCategory.insumo, unit: 'L', stock: 3, minStock: 4, cost: 2.50, price: 0, supplierId: '1'),
  MockProduct(id: '3', name: 'Pollo entero', category: ProductCategory.insumo, unit: 'kg', stock: 12, minStock: 5, cost: 3.20, price: 0, supplierId: '2'),
  MockProduct(id: '4', name: 'Tomate riñón', category: ProductCategory.insumo, unit: 'kg', stock: 2, minStock: 3, cost: 0.90, price: 0, supplierId: '2'),
  MockProduct(id: '5', name: 'Cebolla colorada', category: ProductCategory.insumo, unit: 'kg', stock: 0, minStock: 2, cost: 0.60, price: 0, supplierId: '2'),
  MockProduct(id: '6', name: 'Camarón pelado', category: ProductCategory.insumo, unit: 'kg', stock: 8, minStock: 3, cost: 9.50, price: 0, supplierId: '3'),
  MockProduct(id: '7', name: 'Seco de pollo', category: ProductCategory.plato, unit: 'porción', stock: 0, minStock: 0, cost: 2.20, price: 4.50, supplierId: ''),
  MockProduct(id: '8', name: 'Ceviche de camarón', category: ProductCategory.plato, unit: 'porción', stock: 0, minStock: 0, cost: 4.50, price: 8.00, supplierId: ''),
  MockProduct(id: '9', name: 'Guatita', category: ProductCategory.plato, unit: 'porción', stock: 0, minStock: 0, cost: 2.80, price: 5.00, supplierId: ''),
];
