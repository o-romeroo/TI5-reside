import parkingService from './parking_service.js';
import parkingRepository from '../../infrastructure/repositories/parking_repository.js';
import residentRepository from '../../infrastructure/repositories/resident_repository.js';

jest.mock('../../infrastructure/repositories/parking_repository.js', () => ({
  create: jest.fn(), countParkingsByApartment: jest.fn(), findAll: jest.fn(),
  findById: jest.fn(), findByResidentId: jest.fn(), findByApartment: jest.fn(),
  findByCondominiumId: jest.fn(), findAvailableParkings: jest.fn(), update: jest.fn(),
  delete: jest.fn(), reserveParking: jest.fn(), cancelReservation: jest.fn(),
  findExpiredReservations: jest.fn(), findExpiredDailyParkings: jest.fn(),
  findReservationsByResidentId: jest.fn(),
}));

jest.mock('../../infrastructure/repositories/resident_repository.js', () => ({
  findById: jest.fn(), findAllByCondo: jest.fn(),
}));

jest.spyOn(console, 'log').mockImplementation(() => {});
jest.spyOn(console, 'warn').mockImplementation(() => {});
jest.spyOn(console, 'error').mockImplementation(() => {});

describe('ParkingService', () => {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const validParkingData = {
    resident_id: 1, condominium_id: 1, apartment: '101', location: 'G1-A',
    type: 'diario', price: 20, is_covered: true,
    available_date: tomorrow.toISOString().split('T')[0], start_time: '10:00', end_time: '18:00',
  };

  beforeEach(() => {
    jest.restoreAllMocks();
  });

  describe('createParking', () => {
    it('should create a parking spot successfully', async () => {
      residentRepository.findById.mockResolvedValue({ id: 1 });
      residentRepository.findAllByCondo.mockResolvedValue([{ apartment: '101' }]);
      parkingRepository.countParkingsByApartment.mockResolvedValue(0);
      parkingRepository.create.mockResolvedValue({ id: 1, ...validParkingData });
      await parkingService.createParking(validParkingData);
      expect(parkingRepository.create).toHaveBeenCalledWith(validParkingData);
    });

    it('should throw an error if apartment does not exist in the condominium', async () => {
      residentRepository.findById.mockResolvedValue({ id: 1 });
      residentRepository.findAllByCondo.mockResolvedValue([{ apartment: '102' }]); // Apto 101 não existe
      await expect(parkingService.createParking(validParkingData)).rejects.toThrow('Apartamento não encontrado no condomínio');
    });

    it('should re-throw an error from the catch block', async () => {
      const dbError = new Error('DB connection failed');
      residentRepository.findById.mockRejectedValue(dbError);
      await expect(parkingService.createParking(validParkingData)).rejects.toThrow(dbError);
    });
  });

  describe('validateParkingData', () => {
    it('should throw an error for equal start and end times', () => {
      const data = { ...validParkingData, start_time: '12:00', end_time: '12:00' };
      expect(() => parkingService.validateParkingData(data)).toThrow('Horários de início e fim não podem ser iguais');
    });

    it('should correctly handle and convert english weekdays', () => {
      const data = { type: 'mensal', location: 'L1', apartment: 'A1', price: 100, is_covered: true, monday: true };
      parkingService.validateParkingData(data);
      expect(data.segunda).toBe(true);
    });
  });

  describe('Simple Data Finders', () => {
    it.each([
      ['getAllParkings', 'findAll'], ['getParkingById', 'findById', 1],
      ['getParkingsByApartment', 'findByApartment', '101', 1],
      ['getParkingsByCondominiumId', 'findByCondominiumId', 1],
      ['findAvailableParkings', 'findAvailableParkings', {}],
    ])('%s should call the correct repository method', async (serviceMethod, repoMethod, ...args) => {
      parkingRepository[repoMethod].mockResolvedValue([]);
      await parkingService[serviceMethod](...args);
      expect(parkingRepository[repoMethod]).toHaveBeenCalledWith(...args);
    });
  });

  describe('Data Finders with Formatting', () => {
    const mockParkingInstance = { get: () => ({ id: 1, owner: { first_name: 'Test' } }) };
    
    it('getParkingsByResidentId should call repository and format results', async () => {
      parkingRepository.findByResidentId.mockResolvedValue([mockParkingInstance]);
      const results = await parkingService.getParkingsByResidentId(1);
      expect(parkingRepository.findByResidentId).toHaveBeenCalledWith(1);
      expect(results[0]).toHaveProperty('owner_name');
    });

    it('getReservationsByResidentId should call repository and format results', async () => {
      parkingRepository.findReservationsByResidentId.mockResolvedValue([mockParkingInstance]);
      const results = await parkingService.getReservationsByResidentId(1);
      expect(parkingRepository.findReservationsByResidentId).toHaveBeenCalledWith(1);
      expect(results[0]).toHaveProperty('owner_name');
    });
  });

  describe('formatParkingResponse', () => {
    it('should handle parking with owner but no reserver', () => {
      const owner = { id: 1, first_name: 'John', last_name: 'Doe' };
      const parkingInstance = { get: () => ({ owner, reserver: null }) };
      const result = parkingService.formatParkingResponse(parkingInstance);
      expect(result.owner_name).toBe('John Doe');
      expect(result.reserver_name).toBeNull();
    });
  });

  describe('Error Path Coverage', () => {
    it.each([
      ['updateParking', 'Vaga não encontrada', 1, {}],
      ['deleteParking', 'Vaga não encontrada', 1],
      ['requestParking', 'Vaga não encontrada', 1, 1],
      ['cancelRequest', 'Vaga não encontrada', 1],
    ])('%s should throw error if parking is not found', async (method, error, ...args) => {
      parkingRepository.findById.mockResolvedValue(null);
      await expect(parkingService[method](...args)).rejects.toThrow(error);
    });
    
    it('requestParking should throw error if resident is not found', async () => {
      parkingRepository.findById.mockResolvedValue({ id: 1, status: 'disponivel', type: 'mensal' });
      residentRepository.findById.mockResolvedValue(null);
      await expect(parkingService.requestParking(1, 999)).rejects.toThrow('Residente não encontrado');
    });

    it('cancelRequest should throw error if parking is not reserved', async () => {
      parkingRepository.findById.mockResolvedValue({ id: 1, status: 'disponivel' });
      await expect(parkingService.cancelRequest(1)).rejects.toThrow('Vaga não está reservada');
    });
    
    it('cancelRequest should successfully cancel a valid request', async () => {
        parkingRepository.findById.mockResolvedValue({ id: 1, status: 'reservado' });
        await parkingService.cancelRequest(1);
        expect(parkingRepository.cancelReservation).toHaveBeenCalledWith(1);
    });
  });

  describe('Expiration Checks', () => {
    it('checkExpiredReservations should process reservations and call daily check', async () => {
      const expiredReservations = [{ id: 10 }, { id: 11 }];
      parkingRepository.findExpiredReservations.mockResolvedValue(expiredReservations);
      jest.spyOn(parkingService, 'checkExpiredDailyParkings').mockResolvedValue({ deletedCount: 1 });
      
      const result = await parkingService.checkExpiredReservations();
      
      expect(parkingRepository.cancelReservation).toHaveBeenCalledTimes(2);
      expect(result.canceledCount).toBe(2);
    });

    it('checkExpiredDailyParkings should process expired daily parkings', async () => {
      const expiredParkings = [{ id: 20 }, { id: 21 }];
      parkingRepository.findExpiredDailyParkings.mockResolvedValue(expiredParkings);

      const result = await parkingService.checkExpiredDailyParkings();
      
      expect(parkingRepository.delete).toHaveBeenCalledTimes(2);
      expect(result.deletedCount).toBe(2);
    });
  });
});