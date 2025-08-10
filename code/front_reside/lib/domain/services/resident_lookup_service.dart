import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';

class ResidentLookupService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<String?> getResidentNameById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/residents/infos$id'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return "${data['first_name']} ${data['last_name']}";
    }
    return null;
  }
}