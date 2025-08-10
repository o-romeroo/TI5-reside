import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/repositories/admin_invite_repository.dart';
import '../models/admin_invite_model.dart';
import '../../utils/api_config.dart';

class AdminInviteRepositoryImpl implements AdminInviteRepository {
  final String baseUrl = ApiConfig.baseUrl;

  AdminInviteRepositoryImpl();

  @override
  Future<void> sendInvites(AdminInviteModel invite) async {
    final url = Uri.parse('${baseUrl}/invite');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(invite.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Falha ao enviar convites: ${response.body}');
    }
  }
}