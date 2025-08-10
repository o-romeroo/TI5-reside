import express from 'express';
import ParkingService from '../../core/services/parking_service.js';
import VerifyFirebaseToken from '../middleware/verify_firebase_token.js';
import ResidentService from '../../core/services/resident_service.js';
import Parking from '../../core/models/parking.js'; 
import residentRepository from '../../infrastructure/repositories/resident_repository.js'; // ← FALTANDO
import notificationService from '../../core/services/notification_service.js';


const router = express.Router();

/**
 * @swagger
 * /parkings:
 *   post:
 *     tags:
 *       - Estacionamento
 *     summary: Criar nova vaga de estacionamento
 *     description: Permite que um morador disponibilize uma vaga para aluguel
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ParkingCreateRequest'
 *     responses:
 *       '201':
 *         description: Vaga criada com sucesso
 *       '400':
 *         description: Dados inválidos ou limite de vagas por apartamento excedido
 */
router.post('/parkings', async (req, res) => {
  try {
    const parkingData = req.body;
    const newParking = await ParkingService.createParking(parkingData);
    res.status(201).json(newParking);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

/**
 * @swagger
 * /parkings:
 *   get:
 *     tags:
 *       - Estacionamento
 *     summary: Listar todas as vagas
 *     description: Retorna todas as vagas de estacionamento cadastradas
 *     responses:
 *       '200':
 *         description: Lista de vagas retornada com sucesso
 *       '500':
 *         description: Erro interno do servidor
 */
router.get('/parkings', async (req, res) => {
  try {
    const parkings = await ParkingService.getAllParkings();
    res.status(200).json(parkings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * @swagger
 * /condos/{condominiumId}/parkings:
 *   get:
 *     tags:
 *       - Estacionamento
 *     summary: Listar vagas de um condomínio
 *     parameters:
 *       - name: condominiumId
 *         in: path
 *         required: true
 *         description: ID do condomínio
 *         schema:
 *           type: integer
 *     responses:
 *       '200':
 *         description: Lista de vagas do condomínio
 *       '500':
 *         description: Erro interno do servidor
 */
router.get('/condos/:condominiumId/parkings', async (req, res) => {
  try {
    const { condominiumId } = req.params;
    const parkings = await ParkingService.getParkingsByCondominiumId(condominiumId);
    res.status(200).json(parkings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * @swagger
 * /condos/{condominiumId}/apartments/{apartment}/parkings:
 *   get:
 *     tags:
 *       - Estacionamento
 *     summary: Listar vagas de um apartamento
 *     parameters:
 *       - name: condominiumId
 *         in: path
 *         required: true
 *         description: ID do condomínio
 *         schema:
 *           type: integer
 *       - name: apartment
 *         in: path
 *         required: true
 *         description: Número do apartamento
 *         schema:
 *           type: string
 *     responses:
 *       '200':
 *         description: Lista de vagas do apartamento
 *       '500':
 *         description: Erro interno do servidor
 */
router.get('/condos/:condominiumId/apartments/:apartment/parkings', async (req, res) => {
  try {
    const { condominiumId, apartment } = req.params;
    const parkings = await ParkingService.getParkingsByApartment(apartment, condominiumId);
    res.status(200).json(parkings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * @swagger
 * /parkings/available:
 *   get:
 *     tags:
 *       - Estacionamento
 *     summary: Buscar vagas disponíveis
 *     description: Busca vagas disponíveis com base em filtros como tipo, data, horário, etc.
 *     parameters:
 *       - name: condominium_id
 *         in: query
 *         description: ID do condomínio
 *         schema:
 *           type: integer
 *       - name: location
 *         in: query
 *         description: Localização da vaga (para busca parcial)
 *         schema:
 *           type: string
 *       - name: type
 *         in: query
 *         description: Tipo de aluguel (diário ou mensal)
 *         schema:
 *           type: string
 *           enum: [diario, mensal]
 *       - name: max_price
 *         in: query
 *         description: Preço máximo
 *         schema:
 *           type: number
 *       - name: is_covered
 *         in: query
 *         description: Se a vaga é coberta
 *         schema:
 *           type: boolean
 *       - name: date
 *         in: query
 *         description: Data disponível (para vagas diárias)
 *         schema:
 *           type: string
 *           format: date
 *       - name: start_time
 *         in: query
 *         description: Hora de início (para vagas diárias)
 *         schema:
 *           type: string
 *       - name: end_time
 *         in: query
 *         description: Hora de fim (para vagas diárias)
 *         schema:
 *           type: string
 *       - name: weekdays
 *         in: query
 *         description: Dias da semana (para vagas mensais), formato JSON array de booleans
 *         schema:
 *           type: string
 *     responses:
 *       '200':
 *         description: Lista de vagas disponíveis
 *       '500':
 *         description: Erro interno do servidor
 */
router.get('/parkings/available', async (req, res) => {
  try {
    const filters = {
      condominiumId: req.query.condominium_id,
      location: req.query.location,
      type: req.query.type,
      maxPrice: req.query.max_price ? parseFloat(req.query.max_price) : undefined,
      isCovered: req.query.is_covered !== undefined ? req.query.is_covered === 'true' : undefined,
    };

    // Tratar filtros específicos por tipo
    if (filters.type === 'daily') {
      filters.date = req.query.date;
      filters.startTime = req.query.start_time;
      filters.endTime = req.query.end_time;
    } else if (filters.type === 'monthly') {
      // Converter string de dias da semana para array de booleans
      if (req.query.weekdays) {
        filters.weekdays = JSON.parse(req.query.weekdays);
      }
    }

    const availableParkings = await ParkingService.findAvailableParkings(filters);
    res.status(200).json(availableParkings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * @swagger
 * /residents/{residentId}/parkings:
 *   get:
 *     tags:
 *       - Estacionamento
 *     summary: Listar vagas de um residente
 *     parameters:
 *       - name: residentId
 *         in: path
 *         required: true
 *         description: ID do residente
 *         schema:
 *           type: integer
 *     responses:
 *       '200':
 *         description: Lista de vagas do residente
 *       '500':
 *         description: Erro interno do servidor
 */
router.get('/residents/:residentId/parkings', async (req, res) => {
  try {
    const { residentId } = req.params;
    const parkings = await ParkingService.getParkingsByResidentId(residentId);
    res.status(200).json(parkings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * @swagger
 * /parkings/{id}:
 *   get:
 *     tags:
 *       - Estacionamento
 *     summary: Obter detalhes de uma vaga específica
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         description: ID da vaga
 *         schema:
 *           type: integer
 *     responses:
 *       '200':
 *         description: Detalhes da vaga
 *       '400':
 *         description: ID inválido
 *       '404':
 *         description: Vaga não encontrada
 *       '500':
 *         description: Erro interno do servidor
 */
router.get('/parkings/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    
    if (isNaN(id)) {
      return res.status(400).json({ message: 'ID da vaga deve ser um número válido' });
    }

    const parking = await ParkingService.getParkingById(id);
    
    if (!parking) {
      return res.status(404).json({ message: 'Vaga não encontrada' });
    }
    
    res.status(200).json(parking);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * @swagger
 * /parkings/{id}:
 *   put:
 *     tags:
 *       - Estacionamento
 *     summary: Atualizar uma vaga
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         description: ID da vaga
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ParkingCreateRequest'
 *     responses:
 *       '200':
 *         description: Vaga atualizada com sucesso
 *       '400':
 *         description: Dados inválidos
 *       '404':
 *         description: Vaga não encontrada
 */
router.put('/parkings/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    
    if (isNaN(id)) {
      return res.status(400).json({ message: 'ID da vaga deve ser um número válido' });
    }

    const parkingData = req.body;
    const updatedParking = await ParkingService.updateParking(id, parkingData);
    
    if (!updatedParking) {
      return res.status(404).json({ message: 'Vaga não encontrada' });
    }
    
    res.status(200).json(updatedParking);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

/**
 * @swagger
 * /parkings/{id}:
 *   delete:
 *     tags:
 *       - Estacionamento
 *     summary: Remover uma vaga
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         description: ID da vaga
 *         schema:
 *           type: integer
 *     responses:
 *       '204':
 *         description: Vaga removida com sucesso
 *       '400':
 *         description: ID inválido
 *       '404':
 *         description: Vaga não encontrada
 *       '500':
 *         description: Erro interno do servidor
 */
router.delete('/parkings/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    
    if (isNaN(id)) {
      return res.status(400).json({ message: 'ID da vaga deve ser um número válido' });
    }

    const result = await ParkingService.deleteParking(id);
    
    if (!result) {
      return res.status(404).json({ message: 'Vaga não encontrada' });
    }
    
    res.status(204).end();
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * @swagger
 * /parkings/{id}/request:
 *   post:
 *     tags:
 *       - Estacionamento
 *     summary: Solicitar uma vaga
 *     description: Permite que um morador solicite a reserva de uma vaga disponível
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         description: ID da vaga
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ParkingRequestBody'
 *     responses:
 *       '200':
 *         description: Solicitação realizada com sucesso
 *       '400':
 *         description: ID inválido ou vaga já reservada
 */
router.post('/parkings/:id/request', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    
    if (isNaN(id)) {
      return res.status(400).json({ message: 'ID da vaga deve ser um número válido' });
    }

    const { resident_id } = req.body;
    
    if (!resident_id) {
      return res.status(400).json({ message: 'ID do residente é obrigatório' });
    }
    
    const result = await ParkingService.requestParking(id, resident_id);
    res.status(200).json(result);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

/**
 * @swagger
 * /parkings/{id}/cancel-request:
 *   post:
 *     tags:
 *       - Estacionamento
 *     summary: Cancelar uma solicitação de vaga
 *     description: Cancela uma reserva de vaga e a torna disponível novamente
 *     parameters:
 *       - name: id
 *         in: path
 *         required: true
 *         description: ID da vaga
 *         schema:
 *           type: integer
 *     responses:
 *       '200':
 *         description: Solicitação cancelada com sucesso
 *       '400':
 *         description: ID inválido ou vaga não está reservada
 */
router.post('/parkings/:id/cancel-request', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    
    if (isNaN(id)) {
      return res.status(400).json({ message: 'ID da vaga deve ser um número válido' });
    }
    
    const result = await ParkingService.cancelRequest(id);
    res.status(200).json(result);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

/**
 * @swagger
 * /parkings/check-expired:
 *   post:
 *     tags:
 *       - Estacionamento
 *     summary: Verificar reservas expiradas
 *     description: Verifica e cancela automaticamente reservas que expiraram
 *     responses:
 *       '200':
 *         description: Reservas expiradas verificadas com sucesso
 *       '500':
 *         description: Erro interno do servidor
 */
router.post('/parkings/check-expired', async (req, res) => {
  try {
    const result = await ParkingService.checkExpiredReservations();
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

/**
 * @swagger
 * /residents/{residentId}/reserved-parkings:
 *   get:
 *     tags:
 *       - Estacionamento
 *     summary: Listar vagas reservadas por um residente
 *     parameters:
 *       - name: residentId
 *         in: path
 *         required: true
 *         description: ID do residente
 *         schema:
 *           type: integer
 *     responses:
 *       '200':
 *         description: Lista de vagas reservadas pelo residente
 *       '500':
 *         description: Erro interno do servidor
 */
router.get('/residents/:residentId/reserved-parkings', async (req, res) => {
  try {
    const { residentId } = req.params;
    const reservations = await ParkingService.getReservationsByResidentId(residentId);
    res.status(200).json(reservations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// No parking_route.js, substitua a rota /parkings/:id/rent por:

// Atualizar a rota /parkings/:id/rent no parking_route.js:

router.post('/parkings/:id/rent', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    
    if (isNaN(id)) {
      return res.status(400).json({ message: 'ID da vaga deve ser um número válido' });
    }

    const { renter_id } = req.body;
    
    if (!renter_id) {
      return res.status(400).json({ message: 'ID do locatário é obrigatório' });
    }
    
    // Usa o mesmo serviço da rota /request (que já funciona)
    const result = await ParkingService.requestParking(id, renter_id);
    
    // Busca informações do locatário para a notificação
    const renter = await residentRepository.findById(renter_id);
    if (renter) {
      // Busca a vaga para obter o proprietário E as informações da vaga
      const spot = await Parking.findByPk(id);
      if (spot && spot.resident_id) {
        // MUDANÇA: Passa objeto com informações da vaga ao invés de só o ID
        await notificationService.sendParkingRentedNotification(
          spot.resident_id, // ID do proprietário
          {
            id: id,
            apartment: spot.apartment, // Número do apartamento
            location: spot.location,   // Localização da vaga
          },
          `${renter.first_name} ${renter.last_name}` // Nome do locatário
        );
      }
    }
    
    res.status(200).json({
      ...result,
      message: 'Vaga alugada com sucesso. O proprietário foi notificado.',
    });
  } catch (error) {
    console.error('Erro ao alugar vaga:', error);
    res.status(400).json({ message: error.message });
  }
});

export default router;