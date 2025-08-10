import '../../domain/entities/request_entity.dart';
import '../models/request_model.dart';

class RequestMapper {
  static RequestEntity toEntity(RequestModel model) {
    RequestStatus status;
    switch (model.status) {
      case 'open':
        status = RequestStatus.open;
        break;
      case 'closed':
        status = RequestStatus.closed;
        break;
      default:
        status = RequestStatus.unknown;
    }

    return RequestEntity(
      id: model.id,
      title: model.title,
      type: model.type,
      description: model.description,
      status: status,
      response: model.response,
      createdAt: DateTime.parse(model.createdAt),
      closedAt: model.closedAt != null ? DateTime.parse(model.closedAt!) : null,
      creatorName: model.creatorName,
    );
  }
}