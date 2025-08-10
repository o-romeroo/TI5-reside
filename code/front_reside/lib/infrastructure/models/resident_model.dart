class ResidentModel {
  final String id;
  final String firstName;
  final String lastName;
  final String document;
  final String apartment;
  final String contactPhone;
  final String email;
  final String role;

  ResidentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.document,
    required this.apartment,
    required this.contactPhone,
    required this.email,
    required this.role,
  });

  factory ResidentModel.fromJson(Map<String, dynamic> json) {
    return ResidentModel(
      id: json['id']?.toString() ?? '', 
      firstName: json['first_name'],
      lastName: json['last_name'],
      document: json['document'],
      apartment: json['apartment'],
      contactPhone: json['contact_phone'],
      email: json['email'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'document': document,
      'email': email,
      'contact_phone': contactPhone,
      'apartment': apartment,
      'role': role,
    };
  }
}