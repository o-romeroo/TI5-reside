import '../entities/amenity_entity.dart';

abstract class IAmenityRepository {
  Future<List<AmenityEntity>> findAll();
}