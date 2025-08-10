import 'package:firebase_auth/firebase_auth.dart';
import '../../infrastructure/models/admin_invite_model.dart';
import '../../domain/repositories/admin_invite_repository.dart';
import '../../infrastructure/repositories/admin_invite_repository_impl.dart';
import '../../domain/services/resident_service.dart';

class AdminInviteController {
  final AdminInviteRepository _repository;
  final ResidentService _residentService;

  AdminInviteController({
    AdminInviteRepository? repository,
    ResidentService? residentService,
  }) : _repository = repository ?? AdminInviteRepositoryImpl(),
       _residentService = residentService ?? ResidentService();

  Future<void> sendInvites(List<String> emails, List<String> apartments) async {
    final int condominiumId = await _getCondominiumId();

    // Cria um único grupo com todos os emails e apartamentos
    final invite = AdminInviteModel(
      condominiumId: condominiumId,
      invites: [InviteGroup(emails: emails, apartments: apartments)],
    );

    await _repository.sendInvites(invite);
  }

  Future<int> _getCondominiumId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não está logado');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Token de usuário não encontrado');
      }
      final userData = await _residentService.getUserInfo(idToken);
      
      final condominiumId = userData['condominium_id'];
      if (condominiumId == null) {
        throw Exception('Usuário não está associado a nenhum condomínio');
      }

      // Converter String para int se necessário
      if (condominiumId is String) {
        return int.parse(condominiumId);
      } else if (condominiumId is int) {
        return condominiumId;
      } else {
        throw Exception('Formato inválido para condominium_id: $condominiumId');
      }
    } catch (e) {
      print('❌ Erro ao obter condominium_id: $e');
      throw Exception('Erro ao obter informações do condomínio: $e');
    }
  }
}