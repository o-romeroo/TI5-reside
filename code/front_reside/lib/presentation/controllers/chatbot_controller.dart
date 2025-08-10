import 'package:flutter/material.dart';
import '../../domain/services/chatbot_service.dart';
import 'package:file_picker/file_picker.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class ChatbotController extends ChangeNotifier {
  final ChatbotService service;
  final String condoId;

  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  String? lastUploadedFileName;
  DateTime? lastUploadTime;

  ChatbotController({required this.service, required this.condoId});

  Future<void> sendMessage(String question) async {
    if (question.trim().isEmpty) return;

    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    _messages.add(ChatMessage(text: question, isUser: true, time: time));
    notifyListeners();

    final reply = await service.sendMessage(condoId, question);
    _messages.add(ChatMessage(text: reply, isUser: false, time: time));
    notifyListeners();
  }

  Future<String?> pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'docx'],
        allowMultiple: false,
        withData: true, // Importante para mobile
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        final name = file.name;

        // Validações mais robustas
        if (bytes == null || bytes.isEmpty) {
          return 'Erro: Não foi possível ler o arquivo. Tente novamente.';
        }

        if (name.isEmpty) {
          return 'Erro: Nome do arquivo inválido.';
        }

        // Verificar tamanho do arquivo (máximo 50MB)
        if (bytes.length > 50 * 1024 * 1024) {
          return 'Erro: Arquivo muito grande. Máximo permitido: 50MB.';
        }

        // Verificar extensão
        final extension = name.split('.').last.toLowerCase();
        if (!['pdf', 'txt', 'docx'].contains(extension)) {
          return 'Erro: Tipo de arquivo não suportado. Use PDF, TXT ou DOCX.';
        }

        print('📁 Arquivo selecionado: $name (${bytes.length} bytes)');

        final response = await service.uploadRulesFile(
          condoId: condoId,
          fileBytes: bytes,
          fileName: name,
        );

        if (response == null) {
          // Após upload, buscar nome e data atualizados
          final info = await service.fetchLatestUploadedFile(condoId);
          if (info != null) {
            lastUploadedFileName = info['name'];
            lastUploadTime = DateTime.tryParse(info['date']);
            notifyListeners();
          }
          print('✅ Upload realizado com sucesso');
        } else {
          print('❌ Erro no upload: $response');
        }

        return response; // null = sucesso
      }

      return 'Nenhum arquivo selecionado.';
    } catch (e) {
      print('❌ Erro ao selecionar arquivo: $e');
      return 'Erro ao selecionar arquivo: ${e.toString()}';
    }
  }

  Future<void> fetchLatestUploadedFile() async {
    final result = await service.fetchLatestUploadedFile(condoId);
    if (result != null) {
      lastUploadedFileName = result['name'];
      lastUploadTime = DateTime.tryParse(result['date']);
      notifyListeners();
    }
  }
}
