import '../entities/request_entity.dart';

abstract class IRequestRepository {
  Future<List<RequestEntity>> getRequests();
  Future<RequestEntity> createRequest({required String title, required String type, required String description});
  Future<RequestEntity> respondToRequest({required String id, required String response});
}