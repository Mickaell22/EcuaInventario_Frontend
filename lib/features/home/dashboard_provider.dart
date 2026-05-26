import 'package:facilito/core/api/api_client_provider.dart';
import 'package:facilito/features/home/dashboard_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final dio = ref.watch(apiClientProvider).dio;
  final response = await dio.get<Map<String, dynamic>>('/api/dashboard/');
  return DashboardData.fromJson(response.data!);
});
