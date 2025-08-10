import { Router } from 'express';
import residentService from '../../core/services/resident_service.js';
import verifyFirebaseToken from '../middleware/verify_firebase_token.js';


const router = Router();


router.get('/resident/check-or-create', verifyFirebaseToken, async (req, res) => {
  const google_id = req.user.uid;
  // FCM token é opcional via query
  const fcm_token = req.query.fcm_token || null;

  try {
    const resident = await residentService.checkOrCreateUser(google_id, fcm_token);
    return res.status(200).json({ exists: resident.registered });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});


/**
 * @swagger
 * /resident/me:
 *   get:
 *     tags:
 *       - Residentes
 *     summary: Obter informações do residente autenticado
 *     description: Retorna dados do residente com base no token Firebase do usuário logado
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       '200':
 *         description: Informações do residente retornadas com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ResidentInfoResponse'
 *       '401':
 *         description: Token não fornecido ou inválido
 *       '404':
 *         description: Residente não encontrado para o usuário autenticado
 *       '500':
 *         description: Erro interno do servidor
 */
router.get('/resident/me', verifyFirebaseToken, async (req, res) => {
  try {
    const googleId = req.user.uid;

    const result = await residentService.getUserInfoByGoogleId(googleId);

    if (!result) {
      return res.status(404).json({ error: 'Residente não encontrado' });
    }

    return res.status(200).json(result);
  } catch (err) {
    console.error('Erro ao buscar dados do usuário:', err.message);
    return res.status(500).json({ error: 'Erro interno no servidor' });
  }
});





export default router;
