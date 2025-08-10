import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:front_reside/utils/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart'; 

class FeedService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> sendCondominiumMessage({
    required String senderId,
    required String content,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final uri = Uri.parse('$_baseUrl/messages/residents/$senderId/condominium-message');
    var request = http.MultipartRequest('POST', uri);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
        final idToken = await user.getIdToken();
        if (idToken != null) {
            request.headers['Authorization'] = 'Bearer $idToken';
        } else {
            print('FeedService: idToken is null, proceeding without Authorization header.');
        }
    } else {
        print('FeedService: Firebase user is null, proceeding without Authorization header.');
    }

    request.fields['content'] = content;

    if (imageBytes != null && imageName != null && imageName.isNotEmpty) {
      String fileExtension = imageName.split('.').last.toLowerCase();
      MediaType? mediaType;

      if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (fileExtension == 'png') {
        mediaType = MediaType('image', 'png');
      } else {
        print('FeedService: Tipo de arquivo não suportado: $fileExtension. Imagem não será enviada.');

      }

      if (mediaType != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
          contentType: mediaType, 
        ));
      }
    }

    try {
      print('FeedService: Sending message to: $uri');
      print('FeedService: Headers: ${request.headers}');
      print('FeedService: Fields: ${request.fields}');
      if (request.files.isNotEmpty) {
        print('FeedService: Files: ${request.files.first.filename}, ContentType: ${request.files.first.contentType}, length: ${request.files.first.length}');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('FeedService: Response Status: ${response.statusCode}');
      print('FeedService: Response Body: $responseBody');

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(responseBody);
        if (responseData['success'] == true && responseData['messagesSent'] != null) {
          if (responseData['messagesSent'] is List && (responseData['messagesSent'] as List).isNotEmpty) {
            final Map<String, dynamic> messageData = (responseData['messagesSent'] as List).first as Map<String, dynamic>;
            return messageData;
          } else {
             print('FeedService: messagesSent is not a non-empty list or not a list at all.');
             return {'success': true, 'message': 'Mensagem enviada, mas sem dados de mensagem retornados na lista.', 'data': responseData};
          }
        }
        print('FeedService: Success response but unexpected structure or missing messagesSent.');
        return {'success': true, 'message': 'Mensagem enviada com sucesso (estrutura de resposta inesperada).', 'data': responseData};
      } else {
        String errorMessage = 'Falha ao enviar post.';
        try {
          final Map<String, dynamic> errorData = json.decode(responseBody);
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Erro ${response.statusCode}';
        } catch (e) {
          errorMessage = 'Erro ${response.statusCode}: $responseBody';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('FeedService: Error in sendCondominiumMessage: $e');
      throw Exception('Erro de conexão ou ao processar a requisição: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getResidentMessages({
    required String residentId,
  }) async {
    final uri = Uri.parse('$_baseUrl/messages/residents/$residentId/messages');
    
    String? idToken;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      idToken = await user.getIdToken();
    }

    print('FeedService: Getting messages from: $uri');
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
      );

      print('FeedService: Get Messages Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.cast<Map<String, dynamic>>();
      } else {
        String errorMessage = 'Falha ao buscar mensagens.';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Erro ${response.statusCode}';
        } catch (e) {
          errorMessage = 'Erro ${response.statusCode}: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}'; // Limita o tamanho do erro no log
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('FeedService: Error in getResidentMessages: $e');
      throw Exception('Erro de conexão ou ao processar a requisição de mensagens: ${e.toString()}');
    }
  }
}