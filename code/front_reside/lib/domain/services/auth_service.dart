import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
class AuthService {
  final baseUrl = ApiConfig.baseUrl;

  Future<void> sendTokenToBackend() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();

    if (idToken != null) {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        print('Usuário autenticado com backend.');
      } else {
        print('Erro ao autenticar com backend: ${response.body}');
      }
    }
  }
}
