import express from 'express';
import multer from 'multer';
import { uploadRules, chatCondo } from '../../core/services/chatbot_service.js';
import CondominiumService from '../../core/services/condominium_service.js';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 } 
});

const router = express.Router();


// Upload de regras (síndico)
router.post(
  '/:condoId/rules',
  // ensureManager,
  upload.single('file'),
  async (req, res, next) => {
    try {
      const { condoId } = req.params;
      
      // Validações básicas
      if (!req.file) {
        return res.status(400).json({ error: 'Nenhum arquivo enviado' });
      }

      const fileBuffer = req.file.buffer;
      const fileName = req.file.originalname;
      const fileSize = req.file.size;

      console.log(`📁 Upload recebido: ${fileName} (${fileSize} bytes)`);

      // Validar tamanho do arquivo
      if (fileSize > 50 * 1024 * 1024) {
        return res.status(400).json({ error: 'Arquivo muito grande. Máximo: 50MB' });
      }

      // Validar tipo de arquivo
      const allowedExtensions = ['pdf', 'txt', 'docx'];
      const fileExtension = fileName.split('.').pop()?.toLowerCase();
      if (!fileExtension || !allowedExtensions.includes(fileExtension)) {
        return res.status(400).json({ 
          error: 'Tipo de arquivo não suportado. Use: PDF, TXT ou DOCX' 
        });
      }

      // Faz o upload do arquivo (mantém sua lógica atual)
      const result = await uploadRules(condoId, fileBuffer, fileName);

      const data = {
        upload_filename: fileName,
        upload_at: new Date(),
      };
      try{
        await CondominiumService.updateCondominium(condoId, data);
      }
      catch(err){
        console.error('Erro ao atualizar dados do arquivo:', err.message || err);
      }

      res.json(result);
    } catch (err) {
      next(err);
    }
  }
);

// Chat (moradores)
router.post('/:condoId/chat',
  // ensureUser,
  async (req, res, next) => {
    try {
      const { condoId } = req.params;
      const { question, temperature } = req.body;
      const { answer, context } = await chatCondo(condoId, question, temperature);
      res.json({ answer, context });
    } catch (err) {
      next(err);
    }
  }
);

// Get condominium by ID
router.get('/condominiums/:condominiumId', async (req, res, next) => {
  try {
    const { condominiumId } = req.params;
    const condominium = await CondominiumService.getCondominiumById(condominiumId);
    res.json(condominium);
  } catch (err) {
    next(err);
  }
});

router.get('/condominiums/name/:condominiumId', async (req, res, next) => {
  try {
    const { condominiumId } = req.params;
    const condominium = await CondominiumService.getCondominiumNameById(condominiumId);
    res.json(condominium);
  } catch (err) {
    next(err);
  }
});

// Get all condominiums
router.get('/condominiums', async (req, res, next) => {
  try {
    const condominiums = await CondominiumService.getAllCondominiums();
    res.json(condominiums);
  } catch (err) {
    next(err);
  }
});

router.get('/:condoId/rules/latest', async (req, res) => {
  try {
    const { condoId } = req.params;

    const condo = await CondominiumService.getCondomiumFileInfo(condoId);

    if (!condo || !condo.upload_at || !condo.upload_filename) {
      return res.status(404).json({ error: 'Nenhum arquivo encontrado' });
    }

    res.json({
      name: condo.upload_filename,
      date: condo.upload_at,
    });
  } catch (err) {
    res.status(500).json({ error: 'Erro ao buscar dados' });
  }
});


export default router;
