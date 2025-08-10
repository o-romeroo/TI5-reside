import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_config.dart';

class ChatbotService {
  final String baseUrl = ApiConfig.baseUrl;

  String? lastUploadedFileName;
  DateTime? lastUploadTime;

  Future<String> sendMessage(String condoId, String question) async {
    final uri = Uri.parse('$baseUrl/condos/$condoId/chat');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'question': question}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['answer'] ?? 'Resposta vazia';
      } else {
        return 'Erro ${response.statusCode}: ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Erro de conexão: $e';
    }
  }

  Future<String?> uploadRulesFile({
    required String condoId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/condos/$condoId/rules');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );

      print('🚀 Enviando arquivo: $fileName (${fileBytes.length} bytes)');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📡 Status: ${response.statusCode}');
      print('📡 Response: $responseBody');

      if (response.statusCode == 200) {
        return null; // Sucesso
      } else if (response.statusCode == 400) {
        // Tentar extrair mensagem de erro específica
        try {
          final errorData = json.decode(responseBody);
          return errorData['error'] ?? 'Erro de validação do arquivo';
        } catch (e) {
          return 'Arquivo inválido ou corrompido';
        }
      } else {
        return 'Erro no servidor (código ${response.statusCode})';
      }
    } catch (e) {
      return 'Erro ao enviar: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>?> fetchLatestUploadedFile(String condoId) async {
    final uri = Uri.parse('$baseUrl/condos/$condoId/rules/latest');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body); // retorna name e date
      }
    } catch (e) {
      print('Erro ao buscar documento mais recente: $e');
    }

    return null;
  }
}
