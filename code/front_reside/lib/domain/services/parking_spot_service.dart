import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../infrastructure/models/parking_spot_model.dart';
import '../../utils/api_config.dart';

class ParkingSpotService {
  final String baseUrl = ApiConfig.baseUrl; // Troque para seu backend real

  Future<bool> offerSpot(ParkingSpot spot) async {
    final response = await http.post(
      Uri.parse('$baseUrl/parkings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(spot.toJson()),
    );
    print('Status: ${response.statusCode}');
    print('Resposta do backend: ${response.body}');
    return response.statusCode == 201; // Sucesso esperado
  }
}