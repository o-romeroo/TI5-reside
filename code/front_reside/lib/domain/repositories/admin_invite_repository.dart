// lib/repository/invite_repository.dart
import '../../infrastructure/models/admin_invite_model.dart';

abstract class AdminInviteRepository {
  Future<void> sendInvites(AdminInviteModel invite);
}