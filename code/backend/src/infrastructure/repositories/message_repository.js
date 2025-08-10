import { Op } from 'sequelize';
import BaseRepository from './base_repository.js';
import Message from '../../core/models/message.js';
import Resident from '../../core/models/resident.js';

class MessageRepository extends BaseRepository {
  constructor() {
    super(Message);
  }
  
  async getMessagesBetweenResidents(senderId, receiverId, options = {}) {
    const whereClause = {
      [Op.or]: [
        { 
          sender_id: senderId, 
          receiver_id: receiverId 
        },
        { 
          sender_id: receiverId, 
          receiver_id: senderId 
        }
      ]
    };
    
    const messages = await this.model.findAll({ 
      where: whereClause,
      order: [['created_at', 'ASC']],
      ...options
    });

    return this.processMessagesWithImages(messages);
  }
  
  async getUnreadMessagesForResident(residentId) {
    const messages = await this.model.findAll({
      where: {
        receiver_id: residentId,
        is_read: false
      },
      include: ['sender']
    });

    return this.processMessagesWithImages(messages);
  }

  async getResidentsInSameCondominium(residentId) {
    const resident = await Resident.findByPk(residentId);
    if (!resident) {
      throw new Error('Resident not found');
    }

    return Resident.findAll({
      where: {
        condominium_id: resident.condominium_id,
        id: {
          [Op.ne]: residentId
        }
      }
    });
  }

  async getAll(options = {}) {
    const messages = await super.getAll(options);
    return this.processMessagesWithImages(messages);
  }

  processMessagesWithImages(messages) {
    if (!Array.isArray(messages)) {
      return this.processImageInMessage(messages);
    }
    
    return messages.map(message => this.processImageInMessage(message));
  }

  processImageInMessage(message) {
    if (!message) return message;

    const plainMessage = message.get ? message.get({ plain: true }) : message;

    if (plainMessage.image) {
      if (plainMessage.image instanceof Buffer) {
        plainMessage.has_image = true;
        delete plainMessage.image; 
      } else {
        plainMessage.has_image = false;
      }
    } else {
      plainMessage.has_image = false;
    }

    return plainMessage;
  }

  async getMessageImage(messageId) {
    const message = await this.model.findByPk(messageId, {
      attributes: ['id', 'image', 'image_mime_type', 'image_filename']
    });

    if (!message || !message.image) {
      throw new Error('Image not found');
    }

    return {
      image: message.image,
      mimeType: message.image_mime_type,
      fileName: message.image_filename
    };
  }
}

export default MessageRepository;