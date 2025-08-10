import { Op } from 'sequelize';
import Booking from '../../core/models/booking.js';
import IBookingRepository from '../../core/repositories/IBookingRepository.js';

export default class BookingRepository extends IBookingRepository {
  async findOverlapping(amenityId, startTime, endTime) {
    const existingBooking = await Booking.findOne({
      where: {
        amenity_id: amenityId,
        status: 'confirmed',
        [Op.or]: [
          {
            start_time: {
              [Op.lt]: endTime,
            },
            end_time: {
              [Op.gt]: startTime,
            },
          },
        ],
      },
    });
    return existingBooking;
  }

  async save(bookingData) {
    const newBooking = await Booking.create(bookingData);
    return newBooking;
  }
}