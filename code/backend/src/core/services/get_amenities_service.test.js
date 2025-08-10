import GetAmenitiesService from './get_amenities_service.js';
import AmenityRepository from '../../infrastructure/repositories/amenity_repository.js';

jest.mock('../../infrastructure/repositories/amenity_repository.js', () => {
  return jest.fn().mockImplementation(() => {
    return {
      findAll: jest.fn(),
    };
  });
});

describe('GetAmenitiesService', () => {
  let getAmenitiesService;
  let mockAmenityRepository;

  beforeEach(() => {
    jest.clearAllMocks();

    getAmenitiesService = new GetAmenitiesService();

    mockAmenityRepository = getAmenitiesService.amenityRepository;
  });

  describe('execute', () => {
    it('should return a list of amenities when a valid condominiumId is provided', async () => {
      // Arrange
      const condominiumId = 1;
      const mockAmenities = [
        { id: 1, name: 'Piscina', condominium_id: 1 },
        { id: 2, name: 'Academia', condominium_id: 1 },
      ];

      mockAmenityRepository.findAll.mockResolvedValue(mockAmenities);

      // Act
      const result = await getAmenitiesService.execute({ condominiumId });

      // Assert
      expect(mockAmenityRepository.findAll).toHaveBeenCalledTimes(1);
      expect(mockAmenityRepository.findAll).toHaveBeenCalledWith(condominiumId);

      expect(result).toEqual(mockAmenities);
      expect(result.length).toBe(2);
    });

    it('should throw a 400 error if condominiumId is not provided', async () => {
      // Arrange
      const input = { condominiumId: null };

      // Act & Assert
      await expect(getAmenitiesService.execute(input))
        .rejects.toMatchObject({
          message: 'Condominium ID is required.',
          statusCode: 400,
        });

      expect(mockAmenityRepository.findAll).not.toHaveBeenCalled();
    });

    it('should return an empty array if the repository finds no amenities', async () => {
      // Arrange
      const condominiumId = 2;
      const emptyList = [];
      mockAmenityRepository.findAll.mockResolvedValue(emptyList);

      // Act
      const result = await getAmenitiesService.execute({ condominiumId });

      // Assert
      expect(mockAmenityRepository.findAll).toHaveBeenCalledWith(condominiumId);
      expect(result).toEqual([]);
    });
  });
});