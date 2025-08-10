enum ResidentRole { admin, user, unknown }

class ResidentEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String document;
  final String apartment;
  final String contactPhone;
  final String email;
  final ResidentRole role;

  ResidentEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.document,
    required this.apartment,
    required this.contactPhone,
    required this.email,
    required this.role,
  });

  String get fullName => '$firstName $lastName';

  bool get isAdmin => role == ResidentRole.admin;
}