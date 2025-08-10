class RequestModel {
  final String id;
  final String title;
  final String type;
  final String description;
  final String status;
  final String? response;
  final String createdAt;
  final String? closedAt;
  final String creatorName;

  RequestModel({
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

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'].toString(),
      title: json['title'],
      type: json['type'],
      description: json['description'],
      status: json['status'],
      response: json['response'],
      createdAt: json['created_at'],
      closedAt: json['closed_at'],
      creatorName: json['creator_name'],
    );
  }
}