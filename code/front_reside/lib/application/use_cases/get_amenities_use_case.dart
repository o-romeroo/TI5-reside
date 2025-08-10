import '../../domain/entities/amenity_entity.dart';
import '../../domain/repositories/amenity_repository.dart';

class GetAmenitiesUseCase {
  final IAmenityRepository _amenityRepository;

  GetAmenitiesUseCase(this._amenityRepository);

  Future<List<AmenityEntity>> call() async {
    return await _amenityRepository.findAll();
  }
}