// Atualizar o notification_route.js
import express from 'express';
import notificationService from '../../core/services/notification_service.js';

const router = express.Router();

// Atualizar a rota de teste no notification_route.js:

router.post('/test', async (req, res) => {
  const { token, spotId, apartment } = req.body;
  if (!token || !spotId) {
    return res.status(400).json({ message: 'token e spotId são obrigatórios' });
  }
  
  try {
    await admin.messaging().send({
      token,
      notification: {
        title: 'Vaga Alugada!',
        body: `Parabéns, sua vaga no apartamento ${apartment || spotId} acabou de ser alugada.`,
      },
      data: { 
        spotId: String(spotId),
        apartment: String(apartment || spotId)
      },
    });
    res.json({ success: true, message: 'Notificação enviada!' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Atualizar a rota /parking-rented:
router.post('/parking-rented', async (req, res) => {
  const { ownerId, spotInfo, renterName } = req.body;
  
  if (!ownerId || !spotInfo || !renterName) {
    return res.status(400).json({ 
      error: 'ownerId, spotInfo e renterName são obrigatórios' 
    });
  }

  try {
    const success = await notificationService.sendParkingRentedNotification(
      ownerId, 
      spotInfo, // Agora é um objeto com id, apartment, location
      renterName
    );
    
    if (success) {
      res.json({ success: true, message: 'Notificação enviada com sucesso!' });
    } else {
      res.status(500).json({ error: 'Falha ao enviar notificação' });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;