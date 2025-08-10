import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../infrastructure/models/parking_spot_find_model.dart';
import '../../utils/api_config.dart';

class ParkingSpotFindService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<ParkingSpotFind>> getAvailable({Map<String, dynamic>? filters}) async {
    final uri = Uri.parse('$baseUrl/parkings/available').replace(queryParameters: filters);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => ParkingSpotFind.fromJson(e)).toList();
    }
    throw Exception('Erro ao buscar vagas disponíveis');
  }

  Future<ParkingSpotFind> getById(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/parkings/$id'));
    if (res.statusCode == 200) {
      return ParkingSpotFind.fromJson(jsonDecode(res.body));
    }
    throw Exception('Vaga não encontrada');
  }

  Future<void> requestSpot(int id, int residentId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/parkings/$id/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'resident_id': residentId}),
    );
    if (res.statusCode != 200) {
      throw Exception('Erro ao solicitar vaga');
    }
  }

  Future<void> cancelRequest(int id) async {
    final res = await http.post(Uri.parse('$baseUrl/parkings/$id/request/cancel'));
    if (res.statusCode != 200) {
      throw Exception('Erro ao cancelar solicitação');
    }
  }

  Future<void> rentSpot(int spotId, int renterId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/parkings/$spotId/rent'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'renter_id': renterId}),
  );
  
  if (response.statusCode != 200) {
    final error = jsonDecode(response.body)['error'] ?? 'Erro desconhecido';
    throw Exception('Erro ao alugar vaga: $error');
  }
}

}