import Amenity from '../../core/models/amenity.js';
import IAmenityRepository from '../../core/repositories/IAmenityRepository.js';

class AmenityRepository extends IAmenityRepository {
  async findAll(condominiumId) {
    if (!condominiumId) {
      throw new Error('Condominium ID is required to find amenities.');
    }
    try {
      const amenities = await Amenity.findAll({
        where: {
          condominium_id: condominiumId,
        },
      });
      return amenities;
    } catch (error) {
      console.error(`Error fetching amenities for condominium ${condominiumId}:`, error);
      throw new Error("Failed to fetch amenities from database.");
    }
  }
}

export default AmenityRepository;