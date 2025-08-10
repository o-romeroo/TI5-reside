import MessageRepository from '../../infrastructure/repositories/message_repository.js';
import { sendMessage, TOPICS } from './kafka_service.js';
import { Op } from 'sequelize';
import Resident from '../models/resident.js';
import sharp from 'sharp';
import admin from 'firebase-admin'; 

class MessageService {
  constructor(messageRepository = new MessageRepository()) {
    this.messageRepository = messageRepository;
  }

  async compressImage(imageBuffer, mimeType) {
    if (!imageBuffer) return null;

    try {
      let compressor = sharp(imageBuffer);

      if (mimeType === 'image/png') {
        compressor = compressor.png({ quality: 80 });
      } else {
        compressor = compressor.jpeg({ quality: 80 });
      }

      compressor = compressor.resize({
        width: 1200,
        height: 1200,
        fit: 'inside',
        withoutEnlargement: true
      });

      return await compressor.toBuffer();
    } catch (error) {
      console.error('Error compressing image:', error);
      return imageBuffer;
    }
  }

  removeDuplicateMessages(messages, timeThresholdMs = 5000) {
    // Se não tem mensagens ou só uma, não há duplicatas
    if (!messages || messages.length <= 1) return messages;
    
    // Agrupar mensagens pelo sender_id e content (conteúdo da mensagem)
    const groupedBySender = {};
    
    messages.forEach(message => {
      const senderId = message.sender_id;
      const content = message.content;
      const key = `${senderId}:${content}`;
      
      if (!groupedBySender[key]) {
        groupedBySender[key] = [];
      }
      
      groupedBySender[key].push(message);
    });
    
    // Para cada grupo de mensagens do mesmo remetente e conteúdo
    // filtrar mensagens com timestamps próximos
    const uniqueMessages = [];
    
    Object.values(groupedBySender).forEach(senderMessages => {
      // Ordenar mensagens por timestamp
      senderMessages.sort((a, b) => {
        const timeA = new Date(a.created_at).getTime();
        const timeB = new Date(b.created_at).getTime();
        return timeA - timeB;
      });
      
      // Usar um algoritmo de janela deslizante para encontrar grupos de mensagens com timestamps próximos
      const processedGroups = [];
      let currentGroup = [senderMessages[0]];
      
      for (let i = 1; i < senderMessages.length; i++) {
        const currentMsg = senderMessages[i];
        const prevMsg = currentGroup[currentGroup.length - 1];
        
        const timeDiff = new Date(currentMsg.created_at).getTime() - 
                        new Date(prevMsg.created_at).getTime();
        
        if (timeDiff <= timeThresholdMs) {
          // Mensagem dentro do limiar, adicionar ao grupo atual
          currentGroup.push(currentMsg);
        } else {
          // Mensagem fora do limiar, salvar grupo atual e iniciar novo
          processedGroups.push([...currentGroup]);
          currentGroup = [currentMsg];
        }
      }
      
      // Adicionar o último grupo se não estiver vazio
      if (currentGroup.length > 0) {
        processedGroups.push(currentGroup);
      }
      
      // Para cada grupo de mensagens com timestamps próximos, manter apenas uma
      processedGroups.forEach(group => {
        uniqueMessages.push(group[0]);
      });
    });
    
    // Retornar as mensagens únicas ordenadas por timestamp (mais recentes primeiro)
    return uniqueMessages.sort((a, b) => {
      const timeA = new Date(a.created_at).getTime();
      const timeB = new Date(b.created_at).getTime();
      return timeB - timeA; // Ordenação decrescente
    });
  }

  async sendMessage(
    senderResidentId,
    receiverResidentId,
    content,
    sendToAllInCondominium = false,
    imageData = null,
    imageMimeType = null,
    imageFilename = null
  ) {
    if (!senderResidentId || (!receiverResidentId && !sendToAllInCondominium) || !content) {
      throw new Error('Missing required fields for message');
    }

    if (imageData && imageMimeType) {
      if (!['image/jpeg', 'image/jpg', 'image/png'].includes(imageMimeType)) {
        throw new Error('Apenas imagens nos formatos JPEG e PNG são aceitas');
      }

      imageData = await this.compressImage(imageData, imageMimeType);
    }

    if (sendToAllInCondominium) {
      return this.broadcastToCondominium(
        senderResidentId,
        content,
        imageData,
        imageMimeType,
        imageFilename
      );
    }

    const message = await this.messageRepository.create({
      sender_id: senderResidentId,
      receiver_id: receiverResidentId,
      content,
      image: imageData,
      image_mime_type: imageMimeType,
      image_filename: imageFilename,
      is_read: false,
      created_at: new Date()
    });

    try {
      await sendMessage(TOPICS.RESIDENT_MESSAGES, {
        messageId: message.id,
        senderId: senderResidentId,
        receiverId: receiverResidentId,
        content,
        hasImage: !!imageData,
        timestamp: message.created_at
      });
    } catch (error) {
      console.warn('Failed to send message to Kafka, but database operation succeeded:', error.message);
    }

    return message;
  }

  async broadcastToCondominium(
    senderResidentId,
    content,
    imageData = null,
    imageMimeType = null,
    imageFilename = null
  ) {
    if (!senderResidentId || !content) {
      throw new Error('Missing required fields for message');
    }

    if (imageData && imageMimeType) {
      if (!['image/jpeg', 'image/jpg', 'image/png'].includes(imageMimeType)) {
        throw new Error('Apenas imagens nos formatos JPEG e PNG são aceitas');
      }

      imageData = await this.compressImage(imageData, imageMimeType);
    }

    const sender = await Resident.findByPk(senderResidentId);
    if (!sender) {
      throw new Error('Sender resident not found');
    }

    const condominiumId = sender.condominium_id;
    console.log(`Broadcasting message from resident ${senderResidentId} to all residents in condominium ${condominiumId}`);

    const residents = await this.messageRepository.getResidentsInSameCondominium(senderResidentId);

    console.log(`Found ${residents.length} other residents in the same condominium`);

    if (!residents || residents.length === 0) {
      console.log('No other residents found in the same condominium');
      return { sent: 0, messages: [] };
    }

    const messages = [];

    try {
      await sendMessage(TOPICS.CONDOMINIUM_MESSAGES, {
        senderId: senderResidentId,
        condominiumId: condominiumId,
        content,
        hasImage: !!imageData,
        timestamp: new Date(),
        isCondominiumBroadcast: true
      });

      console.log(`Successfully published message to topic ${TOPICS.CONDOMINIUM_MESSAGES}`);
    } catch (error) {
      console.warn(`Failed to send broadcast message to Kafka topic: ${error.message}`);
    }

    for (const resident of residents) {
      try {
        console.log(`Creating message for resident ${resident.id}`);

        const message = await this.messageRepository.create({
          sender_id: senderResidentId,
          receiver_id: resident.id,
          content,
          image: imageData,
          image_mime_type: imageMimeType,
          image_filename: imageFilename,
          is_read: false,
          created_at: new Date()
        });

        messages.push(message);
        console.log(`Successfully created message ID ${message.id} for resident ${resident.id}`);
      } catch (dbError) {
        console.error(`Failed to create message record for resident ${resident.id}:`, dbError);
      }
    }

    console.log(`Successfully sent messages to ${messages.length} residents`);

    return {
      sent: messages.length,
      messages
    };
  }

  async getMessageImage(messageId) {
    try {
      return this.messageRepository.getMessageImage(messageId);
    } catch (error) {
      console.error(`Error retrieving image for message ${messageId}:`, error);
      throw new Error('Failed to retrieve message image');
    }
  }

  async generateProfilePictureUrl(resident) {

    if (!resident || !resident.google_id) {
      console.warn('[generateProfilePictureUrl] Residente ou google_id ausente. Residente:', resident);
      return null;
    }

    try {
      const userRecord = await admin.auth().getUser(resident.google_id);
       return userRecord.photoURL || null;
    } catch (error) {
      console.error(`[generateProfilePictureUrl] Erro ao buscar usuário do Firebase para google_id ${resident.google_id}:`, error.message, error.code);
      return null;
    }
  }

  async getMessagesForResident(residentId, options = {}) {
    const rawMessages = await this.messageRepository.getAll({
      where: {
        [Op.or]: [
          { sender_id: residentId },
          { receiver_id: residentId }
        ]
      },
      include: [
        { model: Resident, as: 'sender' },
        { model: Resident, as: 'receiver' }
      ],
      order: [['created_at', 'DESC']],
      ...options
    });

    // Remover duplicatas antes de processar as fotos de perfil
    const uniqueMessages = this.removeDuplicateMessages(rawMessages);

    const messagesWithProfilePics = await Promise.all(
      uniqueMessages.map(async (message) => {
        let profilePictureUrlSender = null;
        if (message.sender) {
          profilePictureUrlSender = await this.generateProfilePictureUrl(message.sender);
        } 
        
        const messageJson = message.toJSON ? message.toJSON() : { ...message };
        return {
          ...messageJson,
          profile_picture_url_sender: profilePictureUrlSender
        };
      })
    );
    return messagesWithProfilePics;
  }


  async getMessagesBetweenResidents(residentId1, residentId2) {
    const rawMessages = await this.messageRepository.getMessagesBetweenResidents(residentId1, residentId2, {
      include: [
        { model: Resident, as: 'sender' },
        { model: Resident, as: 'receiver' }
      ],
    });

    // Remover duplicatas antes de processar as fotos de perfil
    const uniqueMessages = this.removeDuplicateMessages(rawMessages);

    const messagesWithProfilePics = await Promise.all(
      uniqueMessages.map(async (message) => {
        let profilePictureUrlSender = null;
        if (message.sender) {
          profilePictureUrlSender = await this.generateProfilePictureUrl(message.sender);
        }
        const messageJson = message.toJSON ? message.toJSON() : { ...message };
        return {
          ...messageJson,
          profile_picture_url_sender: profilePictureUrlSender
        };
      })
    );
    return messagesWithProfilePics;
  }

  async markMessageAsRead(messageId) {
    return this.messageRepository.update(messageId, { is_read: true });
  }

  async getUnreadMessagesForResident(residentId) {
    const rawMessages = await this.messageRepository.getUnreadMessagesForResident(residentId);
    
    // Remover duplicatas antes de processar as fotos de perfil
    const uniqueMessages = this.removeDuplicateMessages(rawMessages);
    
    const messagesWithProfilePics = await Promise.all(
      uniqueMessages.map(async (message) => {
        let profilePictureUrlSender = null;
        if (message.sender) {
          profilePictureUrlSender = await this.generateProfilePictureUrl(message.sender);
        }
        const messageJson = message.toJSON ? message.toJSON() : { ...message };
        return {
          ...messageJson,
          profile_picture_url_sender: profilePictureUrlSender
        };
      })
    );
    return messagesWithProfilePics;
  }
}

export default MessageService;