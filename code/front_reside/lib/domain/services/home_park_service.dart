import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../infrastructure/models/home_park_model.dart';
import '../../utils/api_config.dart';

class HomeParkService {
  final baseUrl = ApiConfig.baseUrl;

  Future<List<HomePark>> getOfferedParkings(int residentId) async {
    final response = await http.get(Uri.parse('$baseUrl/residents/$residentId/parkings'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => HomePark.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar vagas ofertadas');
    }
  }

  Future<List<HomePark>> getReservedParkings(int residentId) async {
    final response = await http.get(Uri.parse('$baseUrl/residents/$residentId/reserved-parkings'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => HomePark.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar vagas reservadas');
    }
  }

  Future<void> deleteParking(int parkingId) async {
    final response = await http.delete(Uri.parse('$baseUrl/parkings/$parkingId'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao apagar a vaga');
    }
  }
}