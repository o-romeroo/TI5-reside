import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:front_reside/utils/api_config.dart';
import '../models/request_model.dart';

abstract class IRequestApiDataSource {
  Future<List<RequestModel>> getRequests();
  Future<RequestModel> createRequest({required String title, required String type, required String description});
  Future<RequestModel> respondToRequest({required String id, required String response});
}

class RequestApiDataSource implements IRequestApiDataSource {
  final http.Client client;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final String _baseUrl = ApiConfig.baseUrl;

  RequestApiDataSource({required this.client});

  Future<String> _getToken() async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) throw Exception('Authentication Token not found.');
    return token;
  }

  @override
  Future<List<RequestModel>> getRequests() async {
    final token = await _getToken();
    final response = await client.get(
      Uri.parse('$_baseUrl/requests'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => RequestModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load requests. Status: ${response.statusCode}');
    }
  }

  @override
  Future<RequestModel> createRequest({required String title, required String type, required String description}) async {
    final token = await _getToken();
    final response = await client.post(
      Uri.parse('$_baseUrl/requests'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: json.encode({'title': title, 'type': type, 'description': description}),
    );
    if (response.statusCode == 201) {
      return RequestModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create request. Status: ${response.statusCode}');
    }
  }

  @override
  Future<RequestModel> respondToRequest({required String id, required String response}) async {
    final token = await _getToken();
    final res = await client.put(
      Uri.parse('$_baseUrl/requests/$id/respond'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: json.encode({'response': response}),
    );
    if (res.statusCode == 200) {
      return RequestModel.fromJson(json.decode(res.body));
    } else {
      throw Exception('Failed to respond to request. Status: ${res.statusCode}');
    }
  }
}