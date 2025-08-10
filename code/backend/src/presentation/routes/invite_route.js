import { Router } from 'express';
import inviteService from '../../core/services/invite_service.js';
import residentRepository from '../../infrastructure/repositories/resident_repository.js'; // ✅ Adicione esta linha
import verifyFirebaseToken from '../middleware/verify_firebase_token.js';

const router = Router();

// 1. Enviar convites para lista de e-mails
router.post('/invite', async (req, res) => {
  try {
    const { condominium_id, invites } = req.body;

    if (!condominium_id) {
      return res.status(400).json({ error: 'condominium_id é obrigatório.' });
    }
    if (!Array.isArray(invites) || invites.length === 0) {
      return res.status(400).json({ error: 'A lista de convites é obrigatória.' });
    }

    const allCreated = [];
    
    for (const { emails, apartments } of invites) {
      if (!Array.isArray(emails) || emails.length === 0 || 
          !Array.isArray(apartments) || apartments.length === 0) {
        return res
          .status(400)
          .json({ error: 'Cada convite precisa de emails (array) e apartments (array).' });
      }
      
      if (emails.length !== apartments.length) {
        return res
          .status(400)
          .json({ error: 'O número de emails deve ser igual ao número de apartamentos.' });
      }

      // Processa cada par email/apartamento
      for (let i = 0; i < emails.length; i++) {
        const created = await inviteService.sendInviteEmails(
          [emails[i]], // Um email por vez
          { apartment: apartments[i], condominium_id }
        );
        allCreated.push(...created);
      }
    }

    return res.status(201).json(allCreated);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});


// 2. Vincular morador ao condomínio com o código recebido
router.post('/invite/bind', verifyFirebaseToken, async (req, res) => {
  try {
    const google_id = req.user.uid;
    const {
      invite_code,
      first_name,
      last_name,
      document,
      contact_phone,
      fcm_token   // ← agora é opcional
    } = req.body;

    if (!invite_code || !first_name || !last_name || !document || !contact_phone) {
      return res
        .status(400)
        .json({ error: 'Todos os campos obrigatórios devem ser fornecidos (invite_code, first_name, last_name, document, contact_phone).' });
    }

    // 1) Faz o bind do residente
    const resident = await inviteService.bindResidentToCondo(invite_code, {
      first_name,
      last_name,
      document,
      contact_phone,
      google_id,
    });

    // 2) Persiste o fcm_token no repositório apenas se fornecido
    if (fcm_token && fcm_token.trim() !== '') {
      await residentRepository.update(resident.id, { fcm_token });
      console.log('📱 FCM Token atualizado para o residente:', resident.id);
    } else {
      console.log('📱 Residente cadastrado sem FCM Token - notificações desabilitadas');
    }

    return res.status(201).json(resident);
  } catch (err) {
    return res.status(400).json({ error: err.message });
  }
});



export default router;