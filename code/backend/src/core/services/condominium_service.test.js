import condominiumService from './condominium_service.js';
import condominiumRepository from '../../infrastructure/repositories/condominium_repository.js';

jest.mock('../../infrastructure/repositories/condominium_repository.js');

describe('CondominiumService', () => {

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getCondominiumById', () => {
    it('should call the repository with the correct id and options, and return the result', async () => {
      // Arrange
      const condominiumId = 1;
      const mockCondo = { id: 1, name: 'Residencial Teste', address: {} };
      condominiumRepository.getById.mockResolvedValue(mockCondo);
      const expectedOptions = {
        include: ['name', 'address', 'residents', 'requests']
      };

      // Act
      const result = await condominiumService.getCondominiumById(condominiumId);

      // Assert
      expect(condominiumRepository.getById).toHaveBeenCalledTimes(1);
      expect(condominiumRepository.getById).toHaveBeenCalledWith(condominiumId, expectedOptions);
      expect(result).toEqual(mockCondo);
    });
  });

  describe('getCondominiumNameById', () => {
    it('should return an object with the condominium name if found', async () => {
      // Arrange
      const condominiumId = 1;
      const mockCondo = { id: 1, name: 'Residencial Sol' };
      condominiumRepository.getById.mockResolvedValue(mockCondo);

      // Act
      const result = await condominiumService.getCondominiumNameById(condominiumId);

      // Assert
      expect(condominiumRepository.getById).toHaveBeenCalledWith(condominiumId, { attributes: ['name'] });
      expect(result).toEqual({ name: 'Residencial Sol' });
    });

    it('should return null if condominium is not found', async () => {
      // Arrange
      const condominiumId = 999;
      condominiumRepository.getById.mockResolvedValue(null);

      // Act
      const result = await condominiumService.getCondominiumNameById(condominiumId);

      // Assert
      expect(condominiumRepository.getById).toHaveBeenCalledWith(condominiumId, { attributes: ['name'] });
      expect(result).toBeNull();
    });
  });

  describe('getAllCondominiums', () => {
    it('should call the repository with correct options and return the list of condominiums', async () => {
      // Arrange
      const mockCondoList = [
        { id: 1, name: 'Condo A' },
        { id: 2, name: 'Condo B' }
      ];
      condominiumRepository.getAll.mockResolvedValue(mockCondoList);
      const expectedOptions = {
        include: ['address', 'residents', 'requests']
      };

      // Act
      const result = await condominiumService.getAllCondominiums();

      // Assert
      expect(condominiumRepository.getAll).toHaveBeenCalledTimes(1);
      expect(condominiumRepository.getAll).toHaveBeenCalledWith(expectedOptions);
      expect(result).toEqual(mockCondoList);
    });
  });

  describe('updateCondominium', () => {
    it('should call the repository to update the condominium and return the result', async () => {
      // Arrange
      const condominiumId = 1;
      const updateData = { name: 'New Condo Name' };
      const updatedCondo = { id: 1, name: 'New Condo Name' };
      condominiumRepository.update.mockResolvedValue(updatedCondo);

      // Act
      const result = await condominiumService.updateCondominium(condominiumId, updateData);

      // Assert
      expect(condominiumRepository.update).toHaveBeenCalledTimes(1);
      expect(condominiumRepository.update).toHaveBeenCalledWith(condominiumId, updateData);
      expect(result).toEqual(updatedCondo);
    });

    it('should throw an error if no update data is provided', async () => {
      // Arrange
      const condominiumId = 1;

      // Act & Assert
      await expect(condominiumService.updateCondominium(condominiumId, null)).rejects.toThrow('No update data provided');

      expect(condominiumRepository.update).not.toHaveBeenCalled();
    });
  });

  describe('getCondomiumFileInfo', () => {
    it('should return file info when condominium and file data exist', async () => {
      // Arrange
      const condominiumId = 1;
      const now = new Date();
      const mockCondo = {
        upload_filename: 'regras.pdf',
        upload_at: now,
      };
      condominiumRepository.getById.mockResolvedValue(mockCondo);

      // Act
      const result = await condominiumService.getCondomiumFileInfo(condominiumId);

      // Assert
      expect(condominiumRepository.getById).toHaveBeenCalledWith(condominiumId, { attributes: ['upload_filename', 'upload_at'] });
      expect(result).toEqual({
        upload_filename: 'regras.pdf',
        upload_at: now,
      });
    });

    it('should throw an error if condominium is not found', async () => {
      // Arrange
      const condominiumId = 999;
      condominiumRepository.getById.mockResolvedValue(null);

      // Act & Assert
      await expect(condominiumService.getCondomiumFileInfo(condominiumId))
        .rejects.toThrow('Condomínio não encontrado ou sem arquivo de regras');
    });

    it('should throw an error if upload_filename is missing', async () => {
      // Arrange
      const condominiumId = 1;
      const mockCondo = { upload_filename: null, upload_at: new Date() };
      condominiumRepository.getById.mockResolvedValue(mockCondo);

      // Act & Assert
      await expect(condominiumService.getCondomiumFileInfo(condominiumId))
        .rejects.toThrow('Condomínio não encontrado ou sem arquivo de regras');
    });

    it('should throw an error if upload_at is missing', async () => {
      // Arrange
      const condominiumId = 1;
      const mockCondo = { upload_filename: 'regras.pdf', upload_at: null };
      condominiumRepository.getById.mockResolvedValue(mockCondo);

      // Act & Assert
      await expect(condominiumService.getCondomiumFileInfo(condominiumId))
        .rejects.toThrow('Condomínio não encontrado ou sem arquivo de regras');
    });
  });
});