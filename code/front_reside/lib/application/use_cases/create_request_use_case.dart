import '../../domain/entities/request_entity.dart';
import '../../domain/repositories/request_repository.dart';

class CreateRequestUseCase {
  final IRequestRepository repository;
  CreateRequestUseCase(this.repository);
  Future<RequestEntity> call({required String title, required String type, required String description}) {
    return repository.createRequest(title: title, type: type, description: description);
  }
}