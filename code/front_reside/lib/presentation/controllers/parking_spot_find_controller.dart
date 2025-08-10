import 'package:flutter/material.dart';
import '../../infrastructure/models/parking_spot_find_model.dart';
import '../../domain/services/parking_spot_find_service.dart';

class ParkingSpotFindController extends ChangeNotifier {
  final ParkingSpotFindService _service = ParkingSpotFindService();

  List<ParkingSpotFind> spots = [];
  bool loading = false;
  String? error;

  Future<void> fetchAvailable({Map<String, dynamic>? filters}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      spots = await _service.getAvailable(filters: filters);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> rentSpot(int spotId, int renterId) async {
  try {
    loading = true;
    error = null;
    notifyListeners();
    
    await _service.rentSpot(spotId, renterId);
    
    // Atualiza a lista de vagas disponíveis
    await fetchAvailable();
    
    // Opcional: mostrar mensagem de sucesso
    print('✅ Vaga alugada com sucesso!');
    
  } catch (e) {
    error = e.toString();
    print('❌ Erro ao alugar vaga: $e');
  } finally {
    loading = false;
    notifyListeners();
  }
}

  Future<void> requestSpot(int spotId, int residentId) async {
    await _service.requestSpot(spotId, residentId);
    await fetchAvailable();
  }
}