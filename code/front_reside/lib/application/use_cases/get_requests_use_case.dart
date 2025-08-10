import '../../domain/entities/request_entity.dart';
import '../../domain/repositories/request_repository.dart';

class GetRequestsUseCase {
  final IRequestRepository repository;
  GetRequestsUseCase(this.repository);
  Future<List<RequestEntity>> call() => repository.getRequests();
}