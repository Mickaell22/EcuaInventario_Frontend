import 'package:dio/dio.dart';
import 'package:ecua_inventario/features/chat/chat_api_models.dart';

class ChatService {
  const ChatService(this._dio);

  final Dio _dio;

  Future<ChatRespuesta> enviarMensaje(String texto) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/chat/mensaje/',
      data: {'mensaje': texto},
    );
    return ChatRespuesta.fromJson(response.data!);
  }

  Future<ConfirmarRespuesta> confirmar(ConfirmarRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/chat/confirmar/',
      data: request.toJson(),
    );
    return ConfirmarRespuesta.fromJson(response.data!);
  }
}
