class AmenityModel {
  final String id;
  final String condominiumId;
  final String name;
  final String description;
  final int capacity;

  AmenityModel({
    required this.id,
    required this.condominiumId,
    required this.name,
    required this.description,
    required this.capacity
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      id: json['id'].toString(),
      condominiumId: json['condominium_id'].toString(),
      name: json['name'],
      description: json['description'],
      capacity: json['capacity']
    );
  }
}