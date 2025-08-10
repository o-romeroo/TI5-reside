import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';

class ResidentService {
  final String baseUrl = '${ApiConfig.baseUrl}/resident';

  Future<bool> checkIfResidentExists(
    String googleId,
    String idToken, {
    String? fcmToken,
    int retries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        print('🔍 Tentativa $attempt: verificando residente para $googleId');

        // Constrói a URL base
        String url = '$baseUrl/check-or-create';

        // Adiciona fcm_token apenas se fornecido
        if (fcmToken != null && fcmToken.isNotEmpty) {
          url += '?fcm_token=$fcmToken';
          print('📱 FCM Token incluído na requisição');
        } else {
          print('📱 FCM Token não fornecido - funcionando sem notificações');
        }

        final resp = await http
            .get(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
            )
            .timeout(const Duration(seconds: 10));

        print('📡 Status da resposta: ${resp.statusCode}');
        print('📡 Body da resposta: ${resp.body}');

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final exists = data['exists'] as bool;
          print('✅ Resultado da verificação: $exists');
          return exists;
        } else {
          print('❌ Erro na verificação: Status ${resp.statusCode}');
          return false;
        }
      } catch (e) {
        print('⚠️ Erro na tentativa $attempt: $e');
        if (attempt < retries) {
          await Future.delayed(delay);
          continue;
        }
        print('❌ Todas as tentativas falharam.');
        return false;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>> getUserInfo(String idToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar dados do usuário');
    }
  }
}
