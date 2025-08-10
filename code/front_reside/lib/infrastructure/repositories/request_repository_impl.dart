import '../../domain/entities/request_entity.dart';
import '../../domain/repositories/request_repository.dart';
import '../data_sources/request_api_data_source.dart';
import '../mappers/request_mapper.dart';

class RequestRepositoryImpl implements IRequestRepository {
  final IRequestApiDataSource dataSource;

  RequestRepositoryImpl({required this.dataSource});

  @override
  Future<List<RequestEntity>> getRequests() async {
    final models = await dataSource.getRequests();
    return models.map((model) => RequestMapper.toEntity(model)).toList();
  }

  @override
  Future<RequestEntity> createRequest({required String title, required String type, required String description}) async {
    final model = await dataSource.createRequest(title: title, type: type, description: description);
    return RequestMapper.toEntity(model);
  }

  @override
  Future<RequestEntity> respondToRequest({required String id, required String response}) async {
    final model = await dataSource.respondToRequest(id: id, response: response);
    return RequestMapper.toEntity(model);
  }
}