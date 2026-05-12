import 'package:ecua_inventario/core/api/api_client_provider.dart';
import 'package:ecua_inventario/features/suppliers/supplier_api_models.dart';
import 'package:ecua_inventario/features/suppliers/supplier_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository(ref.watch(apiClientProvider).dio);
});

final proveedoresProvider =
    FutureProvider.autoDispose<List<ProveedorDto>>((ref) {
  return ref.watch(supplierRepositoryProvider).listar();
});

final proveedorProvider =
    FutureProvider.autoDispose.family<ProveedorDto, String>((ref, id) {
  return ref.watch(supplierRepositoryProvider).obtener(id);
});
