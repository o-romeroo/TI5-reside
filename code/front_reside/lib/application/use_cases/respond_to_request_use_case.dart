import '../../domain/entities/request_entity.dart';
import '../../domain/repositories/request_repository.dart';

class RespondToRequestUseCase {
  final IRequestRepository repository;
  RespondToRequestUseCase(this.repository);
  Future<RequestEntity> call({required String id, required String response}) {
    return repository.respondToRequest(id: id, response: response);
  }
}