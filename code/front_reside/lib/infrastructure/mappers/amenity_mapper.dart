import '../../domain/entities/amenity_entity.dart';
import '../models/amenity_model.dart';

class AmenityMapper {
  static AmenityEntity toEntity(AmenityModel model) {
    return AmenityEntity(
      id: model.id,
      condominiumId: model.condominiumId,
      name: model.name,
      description: model.description,
      capacity: model.capacity
    );
  }
}