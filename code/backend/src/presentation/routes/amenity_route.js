import { Router } from 'express';
import verifyFirebaseToken from '../middleware/verify_firebase_token.js';
import GetAmenitiesService from '../../core/services/get_amenities_service.js';
import residentRepository from '../../infrastructure/repositories/resident_repository.js';

const router = Router();

router.get('/amenities', verifyFirebaseToken, async (req, res) => {
  const getAmenitiesService = new GetAmenitiesService();
  const googleId = req.user.uid;

  try {
    const resident = await residentRepository.findByGoogleId(googleId);

    if (!resident || !resident.condominium_id) {
      return res.status(404).json({ message: 'Resident not found or not associated with a condominium.' });
    }

    const amenities = await getAmenitiesService.execute({ 
      condominiumId: resident.condominium_id 
    });
    
    return res.status(200).json(amenities);

  } catch (error) {
    console.error("Error in GET /amenities route:", error);
    return res.status(error.statusCode || 500).json({ message: error.message || 'An internal error occurred.' });
  }
});

export default router;