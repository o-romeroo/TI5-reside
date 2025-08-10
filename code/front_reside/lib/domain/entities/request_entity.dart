enum RequestStatus { open, closed, unknown }

class RequestEntity {
  final String id;
  final String title;
  final String type;
  final String description;
  final RequestStatus status;
  final String? response;
  final DateTime createdAt;
  final DateTime? closedAt;
  final String creatorName;

  RequestEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.status,
    this.response,
    required this.createdAt,
    this.closedAt,
    required this.creatorName,
  });
}