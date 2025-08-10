import { Router } from 'express';
import { Op } from 'sequelize';
import CreateBookingService from '../../core/services/create_booking_service.js'
import verifyFirebaseToken from '../middleware/verify_firebase_token.js';
import residentRepository from '../../infrastructure/repositories/resident_repository.js';
import Booking from '../../core/models/booking.js';
import Amenity from '../../core/models/amenity.js';
import Resident from '../../core/models/resident.js';

const router = Router();

router.post('/bookings', verifyFirebaseToken, async (req, res, next) => {

    const google_id = req.user.uid;
    const { amenityId, startTime, endTime } = req.body;

    const createBookingService = new CreateBookingService();

    try {
      const resident = await residentRepository.findByGoogleId(google_id);

      if (!resident) {
        return res.status(404).json({ message: 'Resident not found for the authenticated user.' });
      }

      const booking = await createBookingService.execute({
        amenityId,
        residentId: resident.id, 
        startTime,
        endTime,
      });

      return res.status(201).json(booking);
    } catch (error) {
      return res.status(error.statusCode || 500).json({ message: error.message });
    }
});

router.get('/bookings', verifyFirebaseToken, async (req, res) => {
  const { startDate, endDate } = req.query;
  const googleId = req.user.uid;

  if (!startDate || !endDate) {
    return res.status(400).json({ message: 'startDate and endDate query parameters are required.' });
  }

  try {
    const resident = await residentRepository.findByGoogleId(googleId);
    if (!resident || !resident.condominium_id) {
      return res.status(404).json({ message: 'Resident not found or not associated with a condominium.' });
    }

    const bookings = await Booking.findAll({
      where: {
        start_time: {
          [Op.between]: [new Date(startDate), new Date(endDate)],
        },
      },
      include: [{
        model: Amenity,
        as: 'amenity',
        where: {
          condominium_id: resident.condominium_id,
        },
        attributes: ['name'],
      },
      {
        model: Resident,
        as: 'resident',
        attributes: ['first_name', 'last_name'],
      }
    ],
      order: [['start_time', 'ASC']],
    });
    
    const formattedBookings = bookings.map(b => ({
        id: b.id,
        amenity_id: b.amenity_id,
        resident_id: b.resident_id,
        start_time: b.start_time,
        end_time: b.end_time,
        status: b.status,
        amenity_name: b.amenity.name,
        resident_name: `${b.resident.first_name} ${b.resident.last_name}`.trim()
    }));

    return res.status(200).json(formattedBookings);

  } catch (error) {
    console.error("Error in GET /bookings route:", error);
    return res.status(500).json({ message: 'An internal error occurred.' });
  }
});

export default router;