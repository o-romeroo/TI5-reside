import MessageService from './message_service.js';
import MessageRepository from '../../infrastructure/repositories/message_repository.js';
import { sendMessage, TOPICS } from './kafka_service.js';
import Resident from '../models/resident.js';
import sharp from 'sharp';
import admin from 'firebase-admin';

jest.mock('../../infrastructure/repositories/message_repository.js', () => {
  return jest.fn().mockImplementation(() => ({
    create: jest.fn(),
    getResidentsInSameCondominium: jest.fn(),
    getMessageImage: jest.fn(),
    getAll: jest.fn(),
    getMessagesBetweenResidents: jest.fn(),
    update: jest.fn(),
    getUnreadMessagesForResident: jest.fn(),
  }));
});

jest.mock('./kafka_service.js', () => ({
  sendMessage: jest.fn(),
  TOPICS: {
    RESIDENT_MESSAGES: 'resident-messages',
    CONDOMINIUM_MESSAGES: 'condominium-messages',
  },
}));

jest.mock('../models/resident.js', () => ({
  findByPk: jest.fn(),
}));

const mockSharpInstance = {
  png: jest.fn().mockReturnThis(),
  jpeg: jest.fn().mockReturnThis(),
  resize: jest.fn().mockReturnThis(),
  toBuffer: jest.fn(),
};
jest.mock('sharp', () => jest.fn(() => mockSharpInstance));

const mockFirebaseGetUser = jest.fn();
jest.mock('firebase-admin', () => ({
  auth: () => ({
    getUser: mockFirebaseGetUser,
  }),
}));

jest.spyOn(console, 'log').mockImplementation(() => {});
jest.spyOn(console, 'warn').mockImplementation(() => {});
jest.spyOn(console, 'error').mockImplementation(() => {});


describe('MessageService', () => {
  let messageService;
  let mockMessageRepository;

  beforeEach(() => {
    jest.clearAllMocks();
    messageService = new MessageService();
    mockMessageRepository = messageService.messageRepository;
  });

  describe('sendMessage', () => {
    it('should create a message, send to Kafka, and return the message', async () => {
      const createdMsg = { id: 1, sender_id: 1, receiver_id: 2, content: 'Hi' };
      mockMessageRepository.create.mockResolvedValue(createdMsg);
      sendMessage.mockResolvedValue(true);

      const result = await messageService.sendMessage(1, 2, 'Hi');

      expect(mockMessageRepository.create).toHaveBeenCalledWith(expect.objectContaining({ sender_id: 1, receiver_id: 2 }));
      expect(sendMessage).toHaveBeenCalledWith(TOPICS.RESIDENT_MESSAGES, expect.objectContaining({ messageId: 1 }));
      expect(result).toEqual(createdMsg);
    });

    it('should compress image before sending', async () => {
      const imageData = Buffer.from('fake-image-data');
      mockSharpInstance.toBuffer.mockResolvedValue(Buffer.from('compressed-data'));
      mockMessageRepository.create.mockResolvedValue({ id: 1 });
      
      await messageService.sendMessage(1, 2, 'Look at this', false, imageData, 'image/jpeg');

      expect(sharp).toHaveBeenCalledWith(imageData);
      expect(mockSharpInstance.jpeg).toHaveBeenCalledWith({ quality: 80 });
      expect(mockMessageRepository.create).toHaveBeenCalledWith(expect.objectContaining({ image: Buffer.from('compressed-data') }));
    });

    it('should call broadcastToCondominium when sendToAllInCondominium is true', async () => {
      const broadcastSpy = jest.spyOn(messageService, 'broadcastToCondominium').mockResolvedValue({ sent: 1 });
      
      await messageService.sendMessage(1, null, 'Hello everyone', true);

      expect(broadcastSpy).toHaveBeenCalledWith(1, 'Hello everyone', null, null, null);
      expect(mockMessageRepository.create).not.toHaveBeenCalled();
      expect(sendMessage).not.toHaveBeenCalled();
    });

    it('should NOT throw if Kafka fails, but should log a warning', async () => {
      const createdMsg = { id: 2, sender_id: 1, receiver_id: 2, content: 'Hi again' };
      mockMessageRepository.create.mockResolvedValue(createdMsg);
      sendMessage.mockRejectedValue(new Error('Kafka is down'));

      const result = await messageService.sendMessage(1, 2, 'Hi again');

      expect(result).toEqual(createdMsg);
      expect(console.warn).toHaveBeenCalledWith('Failed to send message to Kafka, but database operation succeeded:', 'Kafka is down');
    });

    it('should throw an error for invalid input', async () => {
      await expect(messageService.sendMessage(1, null, null)).rejects.toThrow('Missing required fields for message');
      await expect(messageService.sendMessage(1, 2, 'Hi', false, Buffer.from(''), 'image/gif')).rejects.toThrow('Apenas imagens nos formatos JPEG e PNG são aceitas');
    });
  });

  describe('broadcastToCondominium', () => {
    it('should create messages for all residents in a condo and send ONE kafka broadcast', async () => {
      const sender = { id: 1, condominium_id: 10 };
      const otherResidents = [{ id: 2 }, { id: 3 }];
      Resident.findByPk.mockResolvedValue(sender);
      mockMessageRepository.getResidentsInSameCondominium.mockResolvedValue(otherResidents);
      mockMessageRepository.create.mockImplementation(data => Promise.resolve({ id: Math.random(), ...data }));

      const result = await messageService.broadcastToCondominium(1, 'Meeting tonight!');

      expect(Resident.findByPk).toHaveBeenCalledWith(1);
      expect(mockMessageRepository.getResidentsInSameCondominium).toHaveBeenCalledWith(1);
      expect(sendMessage).toHaveBeenCalledTimes(1);
      expect(sendMessage).toHaveBeenCalledWith(TOPICS.CONDOMINIUM_MESSAGES, expect.objectContaining({ condominiumId: 10 }));
      expect(mockMessageRepository.create).toHaveBeenCalledTimes(2);
      expect(mockMessageRepository.create).toHaveBeenCalledWith(expect.objectContaining({ receiver_id: 2 }));
      expect(mockMessageRepository.create).toHaveBeenCalledWith(expect.objectContaining({ receiver_id: 3 }));
      expect(result.sent).toBe(2);
    });

    it('should throw an error if sender is not found', async () => {
      Resident.findByPk.mockResolvedValue(null);
      await expect(messageService.broadcastToCondominium(99, '...')).rejects.toThrow('Sender resident not found');
    });
  });

  describe('getMessagesForResident & other fetchers', () => {
    it('should fetch messages and enrich them with sender profile pictures', async () => {
      const rawMessages = [
        { id: 1, content: 'Msg 1', sender: { id: 1, google_id: 'gid1' }, toJSON: () => rawMessages[0] },
        { id: 2, content: 'Msg 2', sender: { id: 2, google_id: 'gid2' }, toJSON: () => rawMessages[1] },
      ];
      mockMessageRepository.getAll.mockResolvedValue(rawMessages);
      mockFirebaseGetUser
        .mockResolvedValueOnce({ photoURL: 'http://pic.com/1' })
        .mockResolvedValueOnce({ photoURL: 'http://pic.com/2' });
      
      const result = await messageService.getMessagesForResident(1);

      expect(mockMessageRepository.getAll).toHaveBeenCalled();
      expect(mockFirebaseGetUser).toHaveBeenCalledTimes(2);
      expect(mockFirebaseGetUser).toHaveBeenCalledWith('gid1');
      expect(mockFirebaseGetUser).toHaveBeenCalledWith('gid2');
      expect(result).toHaveLength(2);
      expect(result[0].profile_picture_url_sender).toBe('http://pic.com/1');
      expect(result[1].profile_picture_url_sender).toBe('http://pic.com/2');
    });
  });
  
  describe('generateProfilePictureUrl', () => {
    it('should return photoURL from Firebase user record', async () => {
      const resident = { google_id: 'test-google-id' };
      mockFirebaseGetUser.mockResolvedValue({ photoURL: 'http://example.com/photo.jpg' });

      const url = await messageService.generateProfilePictureUrl(resident);

      expect(mockFirebaseGetUser).toHaveBeenCalledWith('test-google-id');
      expect(url).toBe('http://example.com/photo.jpg');
    });

    it('should return null if Firebase user has no photoURL', async () => {
      const resident = { google_id: 'test-google-id' };
      mockFirebaseGetUser.mockResolvedValue({ photoURL: null });

      const url = await messageService.generateProfilePictureUrl(resident);

      expect(url).toBeNull();
    });

    it('should return null and log an error if Firebase throws an error', async () => {
      // Arrange
      const resident = { google_id: 'invalid-id' };
      const firebaseError = new Error('User not found');
      mockFirebaseGetUser.mockRejectedValue(firebaseError);

      // Act
      const url = await messageService.generateProfilePictureUrl(resident);

      // Assert
      expect(url).toBeNull();
      expect(console.error).toHaveBeenCalledWith(
        expect.stringContaining('[generateProfilePictureUrl]'),
        firebaseError.message,
        undefined
      );
    });

    it('should return null if resident or google_id is missing', async () => {
      expect(await messageService.generateProfilePictureUrl(null)).toBeNull();
      expect(await messageService.generateProfilePictureUrl({})).toBeNull();
      expect(mockFirebaseGetUser).not.toHaveBeenCalled();
    });
  });

  describe('markMessageAsRead', () => {
    it('should call the repository to update the message', async () => {
      const messageId = 123;
      mockMessageRepository.update.mockResolvedValue([1]);

      const result = await messageService.markMessageAsRead(messageId);
      
      expect(mockMessageRepository.update).toHaveBeenCalledTimes(1);
      expect(mockMessageRepository.update).toHaveBeenCalledWith(messageId, { is_read: true });
      expect(result).toEqual([1]);
    });
  });
});