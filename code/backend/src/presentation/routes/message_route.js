import express from 'express';
import multer from 'multer';
import MessageService from '../../core/services/message_service.js';

const router = express.Router();
const messageService = new MessageService();

const storage = multer.memoryStorage();
const fileFilter = (req, file, cb) => {
  if (file.mimetype === 'image/jpeg' || file.mimetype === 'image/png') {
    cb(null, true);
  } else {
    cb(new Error('Apenas imagens nos formatos JPEG e PNG são aceitas'), false);
  }
};

const upload = multer({ 
  storage: storage, 
  fileFilter: fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB max
});


// router.post('/residents/:senderId/messages', upload.single('image'), async (req, res) => {
//   try {
//     const { senderId } = req.params;
//     const { receiverId, content } = req.body;

//     if (!receiverId || !content) {
//       return res.status(400).json({ error: 'Receiver ID and message content are required' });
//     }

//     let imageData = null;
//     let imageMimeType = null;
//     let imageFilename = null;

//     if (req.file) {
//       imageData = req.file.buffer;
//       imageMimeType = req.file.mimetype;
//       imageFilename = req.file.originalname;
//     }

//     const message = await messageService.sendMessage(
//       senderId, 
//       receiverId, 
//       content, 
//       false, 
//       imageData, 
//       imageMimeType, 
//       imageFilename
//     );
    
//     res.status(201).json(message);
//   } catch (error) {
//     console.error('Error sending message:', error);
//     res.status(500).json({ error: error.message });
//   }
// });

/**
 * @swagger
 * /messages/residents/{senderId}/condominium-message:
 *   post:
 *     summary: Envia mensagem para todos os moradores do condomínio (broadcast)
 *     tags:
 *       - Messages
 *     parameters:
 *       - in: path
 *         name: senderId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID do morador remetente
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               content:
 *                 type: string
 *                 description: Conteúdo da mensagem
 *               image:
 *                 type: string
 *                 format: binary
 *                 description: Imagem opcional (JPEG ou PNG, até 5MB)
 *             required:
 *               - content
 *     responses:
 *       201:
 *         description: Mensagem enviada para todos os moradores do condomínio
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 messagesSent:
 *                   type: integer
 *                 messages:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Message'
 *       400:
 *         description: Conteúdo da mensagem ausente ou imagem inválida
 *       500:
 *         description: Erro interno do servidor
 */
router.post('/residents/:senderId/condominium-message', upload.single('image'), async (req, res) => {
  try {
    const { senderId } = req.params;
    const { content } = req.body;

    if (!content) {
      return res.status(400).json({ error: 'Message content is required' });
    }

    let imageData = null;
    let imageMimeType = null;
    let imageFilename = null;

    if (req.file) {
      imageData = req.file.buffer;
      imageMimeType = req.file.mimetype;
      imageFilename = req.file.originalname;
    }

    const result = await messageService.broadcastToCondominium(
      senderId, 
      content,
      imageData, 
      imageMimeType, 
      imageFilename
    );
    
    res.status(201).json({
      success: true,
      messagesSent: result.sent,
      messages: result.messages
    });
  } catch (error) {
    console.error('Error broadcasting message to condominium:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * @swagger
 * /messages/{messageId}/image:
 *   get:
 *     summary: Recupera a imagem anexada a uma mensagem
 *     tags:
 *       - Messages
 *     parameters:
 *       - in: path
 *         name: messageId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID da mensagem
 *     responses:
 *       200:
 *         description: Imagem da mensagem retornada com sucesso
 *         content:
 *           image/jpeg:
 *             schema:
 *               type: string
 *               format: binary
 *           image/png:
 *             schema:
 *               type: string
 *               format: binary
 *       404:
 *         description: Imagem não encontrada
 *       500:
 *         description: Erro ao recuperar a imagem
 */
router.get('/:messageId/image', async (req, res) => {
  try {
    const { messageId } = req.params;
    const imageData = await messageService.getMessageImage(messageId);
    
    res.setHeader('Content-Type', imageData.mimeType);
    res.setHeader('Content-Disposition', `inline; filename="${imageData.fileName || 'image.jpg'}"`);
    
    res.send(imageData.image);
  } catch (error) {
    console.error('Error retrieving message image:', error);
    if (error.message === 'Image not found' || error.message === 'Failed to retrieve message image') {
      res.status(404).json({ error: 'Image not found' });
    } else {
      res.status(500).json({ error: 'Failed to retrieve image' });
    }
  }
});

/**
 * @swagger
 * /messages/residents/{residentId}/conversations/{otherResidentId}:
 *   get:
 *     summary: Lista mensagens entre dois moradores (chat 1 para 1).
 *     tags:
 *       - Messages
 *     parameters:
 *       - in: path
 *         name: residentId
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: otherResidentId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Lista de mensagens
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Message'
 *       500:
 *         description: Erro interno do servidor
 */
// CASO IMPLEMENTEMOS O CHAT 1 PARA 1
// router.get('/residents/:residentId/conversations/:otherResidentId', async (req, res) => {
//   try {
//     const { residentId, otherResidentId } = req.params;
//     const messages = await messageService.getMessagesBetweenResidents(residentId, otherResidentId);
//     res.json(messages);
//   } catch (error) {
//     res.status(500).json({ error: error.message });
//   }
// });

/**
 * @swagger
 * /messages/residents/{residentId}/messages:
 *   get:
 *     summary: Lista todas as mensagens recebidas por um morador
 *     tags:
 *       - Messages
 *     parameters:
 *       - in: path
 *         name: residentId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID do morador
 *     responses:
 *       200:
 *         description: Lista de mensagens recebidas
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Message'
 *       500:
 *         description: Erro interno do servidor
 */
router.get('/residents/:residentId/messages', async (req, res) => {
  try {
    const { residentId } = req.params;
    const messages = await messageService.getMessagesForResident(residentId);
    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * @swagger
 * /messages/residents/{residentId}/messages/unread:
 *   get:
 *     summary: Lista todas as mensagens não lidas por um morador
 *     tags:
 *       - Messages
 *     parameters:
 *       - in: path
 *         name: residentId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID do morador
 *     responses:
 *       200:
 *         description: Lista de mensagens não lidas
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Message'
 *       500:
 *         description: Erro interno do servidor
 */
router.get('/residents/:residentId/messages/unread', async (req, res) => {
  try {
    const { residentId } = req.params;
    const messages = await messageService.getUnreadMessagesForResident(residentId);
    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * @swagger
 * /messages/{messageId}/read:
 *   put:
 *     summary: Marca uma mensagem como lida
 *     tags:
 *       - Messages
 *     parameters:
 *       - in: path
 *         name: messageId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID da mensagem
 *     responses:
 *       200:
 *         description: Mensagem marcada como lida
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Message'
 *       500:
 *         description: Erro interno do servidor
 */
router.put('/:messageId/read', async (req, res) => {
  try {
    const { messageId } = req.params;
    const message = await messageService.markMessageAsRead(messageId);
    res.json(message);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;