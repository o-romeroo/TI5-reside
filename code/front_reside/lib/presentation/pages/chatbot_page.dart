import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/chatbot_controller.dart';
import '../../../domain/services/chatbot_service.dart';
import '../../../domain/services/resident_service.dart';
import '../../utils/api_config.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final baseUrl = ApiConfig.baseUrl;
  String? userRole;
  String? condoId;

  late ChatbotController controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _uploading = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final data = await ResidentService().getUserInfo(idToken!);

      final loadedCondoId = data['condominium_id'].toString();
      final ctrl = ChatbotController(
        service: ChatbotService(),
        condoId: loadedCondoId,
      );

      await ctrl.fetchLatestUploadedFile();

      ctrl.addListener(() {
        setState(() {});

        // Garante que o scroll só vai acontecer depois do rebuild
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      });

      setState(() {
        userRole = data['role'];
        condoId = loadedCondoId;
        controller = ctrl;
        _loading = false;
      });
    } catch (e) {
      print('❌ Erro ao buscar dados do usuário: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    controller.sendMessage(_textController.text);
    _textController.clear();
    Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleUpload() async {
    setState(() => _uploading = true);

    final message = await controller.pickAndUploadFile();

    setState(() => _uploading = false);

    if (!mounted) return;

    if (message == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📄 Documento enviado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $message'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} às '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || userRole == null || condoId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return userRole == 'admin' ? _buildAdminView() : _buildChatView();
  }

  Widget _buildAdminView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat do Síndico')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label:
                  _uploading
                      ? const Text('Enviando...')
                      : const Text('Enviar Regras do Condomínio'),
              onPressed: _uploading ? null : _handleUpload,
            ),
          ),
          if (controller.lastUploadedFileName != null &&
              controller.lastUploadTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4,
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${controller.lastUploadedFileName} upload em '
                      '${_formatDate(controller.lastUploadTime!)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildChatMessages()),
          _ChatInput(controller: _textController, onSend: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat do Morador')),
      body: Column(
        children: [
          Expanded(child: _buildChatMessages()),
          _ChatInput(controller: _textController, onSend: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: controller.messages.length,
      itemBuilder: (context, index) {
        final msg = controller.messages[index];
        return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: msg.isUser ? Colors.blue : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft:
                    msg.isUser ? const Radius.circular(20) : Radius.zero,
                bottomRight:
                    msg.isUser ? Radius.zero : const Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(
                    color: msg.isUser ? Colors.white : Colors.black,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    msg.time,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white70 : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1.0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Digite sua mensagem',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
