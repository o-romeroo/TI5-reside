import 'dart:convert';
import 'package:front_reside/infrastructure/models/resident_model.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';

class InviteService {
  final baseUrl = ApiConfig.baseUrl;

  Future<ResidentModel> bindResident({
    required String inviteCode,
    required String firstName,
    required String lastName,
    required String document,
    required String contactPhone,
    String? fcmToken, // Agora é opcional
    required String googleId,
    required String idToken,
  }) async {
    try {
      // Prepara o body da requisição
      final Map<String, dynamic> requestBody = {
        'invite_code': inviteCode,
        'first_name': firstName,
        'last_name': lastName,
        'document': document,
        'contact_phone': contactPhone,
        'google_id': googleId,
      };

      // Inclui FCM token apenas se fornecido
      if (fcmToken != null && fcmToken.isNotEmpty) {
        requestBody['fcm_token'] = fcmToken;
        print('📱 FCM Token incluído no cadastro');
      } else {
        print(
          '📱 Cadastro realizado sem FCM Token - notificações desabilitadas',
        );
      }

      final resp = await http
          .post(
            Uri.parse('$baseUrl/invite/bind'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 201) {
        return ResidentModel.fromJson(jsonDecode(resp.body));
      } else {
        throw Exception('Erro ao vincular residente: ${resp.body}');
      }
    } catch (e) {
      throw Exception('Erro de conexão ao vincular residente: $e');
    }
  }
}
