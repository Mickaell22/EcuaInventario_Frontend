import 'package:ecua_inventario/core/api/api_client_provider.dart';
import 'package:ecua_inventario/features/chat/chat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(apiClientProvider).dio);
});
