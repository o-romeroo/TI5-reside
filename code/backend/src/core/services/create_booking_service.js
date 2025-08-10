import BookingRepository from '../../infrastructure/repositories/booking_repository.js';

class CreateBookingService {
  constructor() {
    this.bookingRepository = new BookingRepository();
  }

  async execute({ amenityId, residentId, startTime, endTime }) {
    const startDateTime = new Date(startTime);
    const endDateTime = new Date(endTime);

    const now = new Date();
    if (startDateTime < now) {
      const error = new Error('Booking cannot be scheduled in the past.');
      error.statusCode = 400;
      throw error;
    }

    if (endDateTime <= startDateTime) {
      const error = new Error('End time must be after start time.');
      error.statusCode = 400;
      throw error;
    }

    const startHour = startDateTime.getHours();
    const endHour = endDateTime.getHours();

    const endMinutes = endDateTime.getMinutes();

    const MIN_HOUR = 10;
    const MAX_HOUR = 22;

    if (startHour < MIN_HOUR || startHour >= MAX_HOUR) {
      const error = new Error(`Bookings can only start between ${MIN_HOUR}:00 and ${MAX_HOUR-1}:59.`);
      error.statusCode = 400;
      throw error;
    }

    if (endHour < MIN_HOUR || endHour > MAX_HOUR || (endHour === MAX_HOUR && endMinutes > 0)) {
       const error = new Error(`Bookings must end by ${MAX_HOUR}:00.`);
       error.statusCode = 400;
       throw error;
    }

    const overlappingBooking = await this.bookingRepository.findOverlapping(amenityId, startTime, endTime);
    if (overlappingBooking) {
      const error = new Error('Booking conflict: The selected time slot is not available.');
      error.statusCode = 409;
      throw error;
    }

    const bookingData = {
      amenity_id: amenityId,
      resident_id: residentId,
      start_time: startTime,
      end_time: endTime,
      status: 'confirmed',
    };

    const createdBooking = await this.bookingRepository.save(bookingData);
    return createdBooking;
  }
}

export default CreateBookingService;