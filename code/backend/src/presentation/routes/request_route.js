import { Router } from 'express';
import verifyFirebaseToken from '../middleware/verify_firebase_token.js';
import residentRepository from '../../infrastructure/repositories/resident_repository.js';
import Request from '../../core/models/request.js';
import Resident from '../../core/models/resident.js';

const router = Router();

router.get('/requests', verifyFirebaseToken, async (req, res) => {
    const googleId = req.user.uid;
    try {
        const resident = await residentRepository.findByGoogleId(googleId);
        if (!resident || !resident.condominium_id) {
            return res.status(404).json({ message: 'Resident not found or not associated with a condominium.' });
        }

        const requests = await Request.findAll({
            include: [
                {
                    model: Resident,
                    as: 'creator',
                    where: { condominium_id: resident.condominium_id },
                    attributes: ['first_name', 'last_name'],
                }
            ],
            order: [['created_at', 'DESC']],
        });

        const formatted = requests.map(r => ({
            id: r.id,
            title: r.title,
            type: r.type,
            description: r.description,
            status: r.status,
            response: r.response,
            created_at: r.created_at,
            closed_at: r.closed_at,
            creator_name: `${r.creator.first_name} ${r.creator.last_name}`.trim(),
        }));

        return res.status(200).json(formatted);
    } catch (error) {
        return res.status(500).json({ message: `Internal server error: ${error.message}` });
    }
});

router.post('/requests', verifyFirebaseToken, async (req, res) => {
    console.log('--- POST /requests ---');
    console.log('Request Body:', req.body);

    const { title, type, description } = req.body;
    const googleId = req.user.uid;

    if (!title || !type || !description) {
        console.error('Validation failed: Missing fields.');
        return res.status(400).json({ message: 'Title, type, and description are required.' });
    }

    try {
        const resident = await residentRepository.findByGoogleId(googleId);
        if (!resident) {
            console.error('Resident not found for googleId:', googleId);
            return res.status(404).json({ message: 'Resident not found.' });
        }

        if (resident.role === 'admin') {
            return res.status(403).json({ message: 'Permission denied. Admins cannot create requests.' });
        }
        
        if (!resident.condominium_id) {
            console.error(`Resident ${resident.id} is not associated with a condominium.`);
            return res.status(400).json({ message: 'User is not associated with a condominium.' });
        }

        console.log(`Creating request for residentId: ${resident.id} in condominiumId: ${resident.condominium_id}`);
        
        const newRequest = await Request.create({
            title,
            type,
            description,
            resident_id: resident.id,
            condominium_id: resident.condominium_id, 
        });

        const createdRequestWithDetails = await Request.findByPk(newRequest.id, {
            include: [{
                model: Resident,
                as: 'creator',
                attributes: ['first_name', 'last_name'],
            }]
        });

        if (!createdRequestWithDetails) {
          return res.status(404).json({ message: 'Could not retrieve created request details.' });
        }
        
        const formattedResponse = {
            id: createdRequestWithDetails.id,
            title: createdRequestWithDetails.title,
            type: createdRequestWithDetails.type,
            description: createdRequestWithDetails.description,
            status: createdRequestWithDetails.status,
            response: createdRequestWithDetails.response,
            created_at: createdRequestWithDetails.created_at,
            closed_at: createdRequestWithDetails.closed_at,
            creator_name: `${createdRequestWithDetails.creator.first_name} ${createdRequestWithDetails.creator.last_name}`.trim(),
        };

        console.log('Request created successfully:', newRequest);
        return res.status(201).json(formattedResponse);

    } catch (error) {
        console.error('--- ERROR in POST /requests ---');
        if (error.name === 'SequelizeValidationError') {
            const errorMessages = error.errors.map(e => e.message).join(', ');
            console.error('Sequelize Validation Error:', errorMessages);
            return res.status(400).json({ message: `Validation Error: ${errorMessages}` });
        }
        console.error(error);
        return res.status(400).json({ message: `Failed to create request: ${error.message}` });
    }
});

router.put('/requests/:id/respond', verifyFirebaseToken, async (req, res) => {
    const { response } = req.body;
    const { id } = req.params;
    const googleId = req.user.uid;

    try {
        const manager = await residentRepository.findByGoogleId(googleId);
        if (!manager || manager.role !== 'admin') {
            return res.status(403).json({ message: 'Permission denied. Only managers can respond.' });
        }

        const requestToUpdate = await Request.findByPk(id);
        if (!requestToUpdate) {
            return res.status(404).json({ message: 'Request not found.' });
        }

        requestToUpdate.response = response;
        requestToUpdate.status = 'closed';
        requestToUpdate.closed_at = new Date();
        await requestToUpdate.save();

        const updatedRequestWithDetails = await Request.findByPk(id, {
            include: [{
                model: Resident,
                as: 'creator',
                attributes: ['first_name', 'last_name'],
            }]
        });
        
        if (!updatedRequestWithDetails) {
            return res.status(404).json({ message: 'Could not retrieve updated request details.' });
        }

        const formattedResponse = {
            id: updatedRequestWithDetails.id,
            title: updatedRequestWithDetails.title,
            type: updatedRequestWithDetails.type,
            description: updatedRequestWithDetails.description,
            status: updatedRequestWithDetails.status,
            response: updatedRequestWithDetails.response,
            created_at: updatedRequestWithDetails.created_at,
            closed_at: updatedRequestWithDetails.closed_at,
            creator_name: `${updatedRequestWithDetails.creator.first_name} ${updatedRequestWithDetails.creator.last_name}`.trim(),
        };

        return res.status(200).json(formattedResponse);
    } catch (error) {
        return res.status(500).json({ message: `Internal server error: ${error.message}` });
    }
});

export default router;