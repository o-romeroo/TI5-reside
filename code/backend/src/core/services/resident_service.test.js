import residentService from './resident_service.js';
import residentRepository from '../../infrastructure/repositories/resident_repository.js';
import Condominium from '../../core/models/condominium.js';

jest.mock('../../infrastructure/repositories/resident_repository.js', () => ({
  findByGoogleId: jest.fn(),
  create: jest.fn(),
  getById: jest.fn(),
  update: jest.fn(),
  updateFcmToken: jest.fn(),
}));

jest.mock('../../core/models/condominium.js');

describe('ResidentService', () => {

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('checkOrCreateUser', () => {
    it('should return an existing resident if found (without updating fcm_token)', async () => {
      const googleId = 'google123';
      const existingResident = { id: 1, google_id: googleId, registered: true, fcm_token: 'token123' };
      residentRepository.findByGoogleId.mockResolvedValue(existingResident);

      const result = await residentService.checkOrCreateUser(googleId);

      expect(residentRepository.findByGoogleId).toHaveBeenCalledWith(googleId);
      expect(residentRepository.create).not.toHaveBeenCalled();
      expect(residentRepository.updateFcmToken).not.toHaveBeenCalled();
      expect(result).toEqual(existingResident);
    });

    it('should create a new resident stub if not found', async () => {
      const googleId = 'new-google-user';
      const newResident = { id: 2, google_id: googleId, registered: false, fcm_token: null };
      residentRepository.findByGoogleId.mockResolvedValue(null);
      residentRepository.create.mockResolvedValue(newResident);

      const result = await residentService.checkOrCreateUser(googleId);

      expect(residentRepository.findByGoogleId).toHaveBeenCalledWith(googleId);
      expect(residentRepository.create).toHaveBeenCalledTimes(1);

      expect(residentRepository.create).toHaveBeenCalledWith(expect.objectContaining({
        google_id: googleId,
        registered: false,
        fcm_token: null,
      }));
      expect(result).toEqual(newResident);
    });

    it('should update the fcm_token for an existing user if a new token is provided', async () => {
      const googleId = 'google123';
      const existingResident = { id: 1, google_id: googleId, registered: true, fcm_token: 'old_token' };
      const newFcmToken = 'new_fresh_token';
      residentRepository.findByGoogleId.mockResolvedValue(existingResident);
      residentRepository.updateFcmToken.mockResolvedValue([1]);

      const result = await residentService.checkOrCreateUser(googleId, newFcmToken);

      expect(residentRepository.findByGoogleId).toHaveBeenCalledWith(googleId);
      expect(residentRepository.create).not.toHaveBeenCalled();
      expect(residentRepository.updateFcmToken).toHaveBeenCalledTimes(1);
      expect(residentRepository.updateFcmToken).toHaveBeenCalledWith(googleId, newFcmToken);
      expect(result.fcm_token).toBe(newFcmToken);
    });
  });

  describe('getUserInfoByGoogleId', () => {
    it('should return formatted user info including fcm_token', async () => {
      const googleId = 'google123';
      const mockResident = {
        id: 1,
        role: 'user',
        condominium_id: 10,
        first_name: 'John',
        last_name: 'Doe',
        apartment: '101',
        fcm_token: 'token123',
        condominium: { name: 'Residencial Topázio' }
      };
      residentRepository.findByGoogleId.mockResolvedValue(mockResident);
      
      const result = await residentService.getUserInfoByGoogleId(googleId);

      expect(result).toEqual({
        role: 'user',
        id: 1,
        condominium_id: 10,
        first_name: 'John',
        last_name: 'Doe',
        apartment: '101',
        condominium_name: 'Residencial Topázio',
        fcm_token: 'token123',
      });
    });

    it('should throw an error if resident is not found', async () => {
      const googleId = 'non-existent-id';
      residentRepository.findByGoogleId.mockResolvedValue(null);
      await expect(residentService.getUserInfoByGoogleId(googleId)).rejects.toThrow('Usuário não encontrado');
    });
  });

  describe('getResidentById', () => {
    it('should call the repository getById with the correct parameters', async () => {
      const residentId = 1;
      const mockResident = { id: 1, name: 'Test User' };
      residentRepository.getById.mockResolvedValue(mockResident);
      
      const result = await residentService.getResidentById(residentId);
      
      expect(residentRepository.getById).toHaveBeenCalledWith(residentId, {
        include: ['requests'],
      });
      expect(result).toEqual(mockResident);
    });
  });

  describe('createResident', () => {
    it('should call repository create with valid data', async () => {
      const residentData = { name: 'Jane Doe', condominium_id: 2 };
      residentRepository.create.mockResolvedValue({ id: 3, ...residentData });
      await residentService.createResident(residentData);
      expect(residentRepository.create).toHaveBeenCalledWith(residentData);
    });
  });

  describe('updateResident', () => {
    it('should call repository update with correct id and data', async () => {
      const residentId = 1;
      const updateData = { apartment: '202' };
      residentRepository.update.mockResolvedValue([1]);
      await residentService.updateResident(residentId, updateData);
      expect(residentRepository.update).toHaveBeenCalledWith(residentId, updateData);
    });
  });
});