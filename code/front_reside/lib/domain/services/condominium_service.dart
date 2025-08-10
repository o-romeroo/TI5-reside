import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';

class CondominiumService {
  final String baseUrl = '${ApiConfig.baseUrl}/condos/condominiums';


  Future<Map<String, dynamic>> getCondoInfo(String idToken, String condoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/name/$condoId'),
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao buscar dados do usuário');
    }
  }
}
