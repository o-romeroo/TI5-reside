import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/api_config.dart';
import '../models/amenity_model.dart';

abstract class IAmenityApiDataSource {
  Future<List<AmenityModel>> fetchAmenities();
}

class AmenityApiDataSource implements IAmenityApiDataSource {
  final http.Client client;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final _baseUrl = ApiConfig.baseUrl;

  AmenityApiDataSource({required this.client});

  @override
  Future<List<AmenityModel>> fetchAmenities() async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    // Adicione um print para depurar a URL e o token que estão sendo enviados
    final url = Uri.parse('$_baseUrl/amenities');
    print('🚀 GET: $url');
    print('🔑 Token: Bearer ${token.substring(0, 20)}...'); // Mostra só o início do token

    final response = await client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // Adicione um print para ver a resposta completa
    print('📡 Status: ${response.statusCode}');
    print('📡 Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AmenityModel.fromJson(json)).toList();
    } else {
      // **A MUDANÇA IMPORTANTE ESTÁ AQUI**
      // Lança uma exceção mais descritiva
      throw Exception(
        'Failed to load amenities. '
        'Status: ${response.statusCode}, '
        'Body: ${response.body}'
      );
    }
  }
}