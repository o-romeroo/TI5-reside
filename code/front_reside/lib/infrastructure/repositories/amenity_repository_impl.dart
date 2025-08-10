import '../../domain/entities/amenity_entity.dart';
import '../../domain/repositories/amenity_repository.dart';
import '../data_sources/amenity_api_data_source.dart';
import '../mappers/amenity_mapper.dart';

class AmenityRepositoryImpl implements IAmenityRepository {
  final IAmenityApiDataSource dataSource;

  AmenityRepositoryImpl({required this.dataSource});

  @override
  Future<List<AmenityEntity>> findAll() async {
    try {
      final amenityModels = await dataSource.fetchAmenities();
      final amenityEntities =
          amenityModels.map((model) => AmenityMapper.toEntity(model)).toList();
      return amenityEntities;
    } catch (e) {
      throw Exception('Failed to retrieve amenities: ${e.toString()}');
    }
  }
}