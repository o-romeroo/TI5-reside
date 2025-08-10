import RequestService from './request_service.js';

describe('RequestService', () => {
  let requestService;
  let mockRequestRepository;

  beforeEach(() => {
    mockRequestRepository = {
      getAll: jest.fn(),
      getById: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    };

    jest.clearAllMocks();

    requestService = new RequestService(mockRequestRepository);
  });

  describe('getRequestsByResidentId', () => {
    it('should call the repository with the correct query and return the result', async () => {
      // Arrange
      const residentId = 123;
      const mockRequests = [{ id: 1, resident_id: residentId, description: 'Leaking pipe' }];
      mockRequestRepository.getAll.mockResolvedValue(mockRequests);

      const expectedQuery = {
        where: { resident_id: residentId },
        include: ['resident', 'condominium'],
      };

      // Act
      const result = await requestService.getRequestsByResidentId(residentId);

      // Assert
      expect(mockRequestRepository.getAll).toHaveBeenCalledTimes(1);
      expect(mockRequestRepository.getAll).toHaveBeenCalledWith(expectedQuery);
      expect(result).toEqual(mockRequests);
    });
  });

  describe('createRequest', () => {
    const requestData = {
      resident_id: 1,
      type: 'maintenance',
      description: 'The elevator is making a weird noise.',
    };

    it('should add status and creation date, then call the repository', async () => {
      // Arrange
      const createdRequest = { id: 1, ...requestData, status: 'open', created_at: new Date() };
      mockRequestRepository.create.mockResolvedValue(createdRequest);

      // Act
      const result = await requestService.createRequest(requestData);

      // Assert
      expect(mockRequestRepository.create).toHaveBeenCalledTimes(1);
      expect(mockRequestRepository.create).toHaveBeenCalledWith({
        ...requestData,
        status: 'open',
        created_at: expect.any(Date),
      });
      expect(result).toEqual(createdRequest);
    });

    it.each([
      { data: { type: 'a', description: 'b' }, field: 'resident_id' },
      { data: { resident_id: 1, description: 'b' }, field: 'type' },
      { data: { resident_id: 1, type: 'a' }, field: 'description' },
    ])('should throw an error if required field "$field" is missing', async ({ data }) => {
      // Act & Assert
      await expect(requestService.createRequest(data)).rejects.toThrow('Missing required fields for request');
      expect(mockRequestRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('updateRequest', () => {
    it('should add a closed_at date when status is updated to "closed"', async () => {
      // Arrange
      const requestId = 1;
      const updateData = { status: 'closed' };
      mockRequestRepository.update.mockResolvedValue([1]);

      // Act
      await requestService.updateRequest(requestId, updateData);

      // Assert
      expect(mockRequestRepository.update).toHaveBeenCalledTimes(1);
      expect(mockRequestRepository.update).toHaveBeenCalledWith(requestId, {
        status: 'closed',
        closed_at: expect.any(Date),
      });
    });

    it('should add a closed_at date when status is updated to "resolved"', async () => {
      // Arrange
      const requestId = 2;
      const updateData = { status: 'resolved' };
      mockRequestRepository.update.mockResolvedValue([1]);

      // Act
      await requestService.updateRequest(requestId, updateData);

      // Assert
      expect(mockRequestRepository.update).toHaveBeenCalledWith(requestId, {
        status: 'resolved',
        closed_at: expect.any(Date),
      });
    });

    it('should NOT add a closed_at date for other status updates', async () => {
      // Arrange
      const requestId = 3;
      const updateData = { status: 'in_progress', response: 'Checking now' };
      mockRequestRepository.update.mockResolvedValue([1]);

      // Act
      await requestService.updateRequest(requestId, updateData);

      // Assert
      expect(mockRequestRepository.update).toHaveBeenCalledWith(requestId, updateData);
      
      const calledWithData = mockRequestRepository.update.mock.calls[0][1];
      expect(calledWithData.closed_at).toBeUndefined();
    });

    it('should throw an error if no update data is provided', async () => {
      // Act & Assert
      await expect(requestService.updateRequest(1, null)).rejects.toThrow('No update data provided');
      expect(mockRequestRepository.update).not.toHaveBeenCalled();
    });
  });
});