import '../../domain/entities/resident_entity.dart';
import '../models/resident_model.dart';

class ResidentMapper {
  static ResidentEntity toEntity(ResidentModel model) {
    ResidentRole role;
    switch (model.role) {
      case 'admin':
        role = ResidentRole.admin;
        break;
      case 'user':
        role = ResidentRole.user;
        break;
      default:
        role = ResidentRole.unknown; 
    }

    return ResidentEntity(
      id: model.id,
      firstName: model.firstName,
      lastName: model.lastName,
      document: model.document,
      apartment: model.apartment,
      contactPhone: model.contactPhone,
      email: model.email,
      role: role,
    );
  }

  static ResidentModel fromEntity(ResidentEntity entity) {
    String roleString;
    switch (entity.role) {
      case ResidentRole.admin:
        roleString = 'admin';
        break;
      case ResidentRole.user:
        roleString = 'user';
        break;
      case ResidentRole.unknown:
        throw ArgumentError('Cannot map unknown role to string for API.');
    }

    return ResidentModel(
      id: entity.id,
      firstName: entity.firstName,
      lastName: entity.lastName,
      document: entity.document,
      apartment: entity.apartment,
      contactPhone: entity.contactPhone,
      email: entity.email,
      role: roleString,
    );
  }
}