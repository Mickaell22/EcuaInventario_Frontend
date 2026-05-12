import 'package:ecua_inventario/core/api/api_client_provider.dart';
import 'package:ecua_inventario/features/products/product_api_models.dart';
import 'package:ecua_inventario/features/products/product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(apiClientProvider).dio);
});

final productosProvider = FutureProvider.autoDispose<List<ProductoDto>>((ref) {
  return ref.watch(productRepositoryProvider).listar();
});

final productoProvider =
    FutureProvider.autoDispose.family<ProductoDto, String>((ref, id) {
  return ref.watch(productRepositoryProvider).obtener(id);
});
