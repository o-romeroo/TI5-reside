import CreateBookingService from './create_booking_service.js';
import BookingRepository from '../../infrastructure/repositories/booking_repository.js';

jest.mock('../../infrastructure/repositories/booking_repository.js', () => {
  return jest.fn().mockImplementation(() => {
    return {
      findOverlapping: jest.fn(),
      save: jest.fn(),
    };
  });
});

describe('CreateBookingService', () => {
  let createBookingService;
  let mockBookingRepository;

  beforeEach(() => {
    jest.clearAllMocks();

    createBookingService = new CreateBookingService();

    mockBookingRepository = createBookingService.bookingRepository;
  });

  const getFutureTime = (startHour, endHour) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const startTime = new Date(tomorrow.setHours(startHour, 0, 0, 0));
    const endTime = new Date(tomorrow.setHours(endHour, 0, 0, 0));
    return { startTime: startTime.toISOString(), endTime: endTime.toISOString() };
  };

  it('should create a booking successfully when all rules are met', async () => {
    // Arrange
    const { startTime, endTime } = getFutureTime(14, 15);
    const input = { amenityId: 1, residentId: 10, startTime, endTime };
    const expectedBookingData = {
      amenity_id: input.amenityId,
      resident_id: input.residentId,
      start_time: input.startTime,
      end_time: input.endTime,
      status: 'confirmed',
    };
    const createdBooking = { id: 1, ...expectedBookingData };

    mockBookingRepository.findOverlapping.mockResolvedValue(null);
    mockBookingRepository.save.mockResolvedValue(createdBooking);

    // Act
    const result = await createBookingService.execute(input);

    // Assert
    expect(mockBookingRepository.findOverlapping).toHaveBeenCalledWith(
      input.amenityId,
      input.startTime,
      input.endTime
    );
    expect(mockBookingRepository.save).toHaveBeenCalledWith(expectedBookingData);
    expect(result).toEqual(createdBooking);
  });

  it('should throw a 409 conflict error if an overlapping booking exists', async () => {
    // Arrange
    const { startTime, endTime } = getFutureTime(16, 17);
    const input = { amenityId: 1, residentId: 10, startTime, endTime };
    const existingBooking = { id: 99, amenity_id: 1, resident_id: 5, start_time: startTime, end_time: endTime };
    
    mockBookingRepository.findOverlapping.mockResolvedValue(existingBooking);

    // Act & Assert
    await expect(createBookingService.execute(input))
      .rejects.toMatchObject({
        message: 'Booking conflict: The selected time slot is not available.',
        statusCode: 409
      });

    expect(mockBookingRepository.save).not.toHaveBeenCalled();
  });

  it('should throw a 400 error if the booking is in the past', async () => {
    // Arrange
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const input = {
      amenityId: 1,
      residentId: 10,
      startTime: yesterday.toISOString(),
      endTime: new Date().toISOString(),
    };

    // Act & Assert
    await expect(createBookingService.execute(input))
      .rejects.toMatchObject({
        message: 'Booking cannot be scheduled in the past.',
        statusCode: 400
      });

    expect(mockBookingRepository.findOverlapping).not.toHaveBeenCalled();
    expect(mockBookingRepository.save).not.toHaveBeenCalled();
  });

  it('should throw a 400 error if end time is not after start time', async () => {
    // Arrange
    const { startTime } = getFutureTime(18, 19);
    const input = {
      amenityId: 1,
      residentId: 10,
      startTime,
      endTime: startTime,
    };

    // Act & Assert
    await expect(createBookingService.execute(input))
      .rejects.toMatchObject({
        message: 'End time must be after start time.',
        statusCode: 400
      });

    expect(mockBookingRepository.findOverlapping).not.toHaveBeenCalled();
  });

  it.each([
    { hour: 9, case: 'too early' },
    { hour: 22, case: 'too late (on the boundary)' },
  ])('should throw a 400 error for invalid start hour ($case)', async ({ hour }) => {
    // Arrange
    const { startTime, endTime } = getFutureTime(hour, hour + 1);
    const input = { amenityId: 1, residentId: 10, startTime, endTime };

    // Act & Assert
    await expect(createBookingService.execute(input))
      .rejects.toMatchObject({
        message: 'Bookings can only start between 10:00 and 21:59.',
        statusCode: 400
      });
      
    expect(mockBookingRepository.findOverlapping).not.toHaveBeenCalled();
  });

  it.each([
    { start: 21, end: 23, case: 'ends after 22:00' },
    { start: 21, end: 22, minutes: 1, case: 'ends at 22:01' },
  ])('should throw a 400 error for invalid end time ($case)', async ({ start, end, minutes = 0 }) => {
    // Arrange
    const { startTime } = getFutureTime(start, end);
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const endTime = new Date(tomorrow.setHours(end, minutes, 0, 0)).toISOString();
    const input = { amenityId: 1, residentId: 10, startTime, endTime };

    // Act & Assert
    await expect(createBookingService.execute(input))
      .rejects.toMatchObject({
        message: 'Bookings must end by 22:00.',
        statusCode: 400
      });
      
    expect(mockBookingRepository.findOverlapping).not.toHaveBeenCalled();
  });
});