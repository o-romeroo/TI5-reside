import AmenityRepository from '../../infrastructure/repositories/amenity_repository.js';

class GetAmenitiesService {
  constructor() {
    this.amenityRepository = new AmenityRepository();
  }

  async execute({ condominiumId }) {
    if (!condominiumId) {
      const error = new Error('Condominium ID is required.');
      error.statusCode = 400;
      throw error;
    }

    const amenities = await this.amenityRepository.findAll(condominiumId);
    return amenities;
  }
}

export default GetAmenitiesService;