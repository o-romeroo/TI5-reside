import {
  initKafka,
  sendMessage,
  createConsumer,
  TOPICS
} from './kafka_service.js';

import {
  Kafka,
  mockProducerConnect,
  mockProducerSend,
  mockConsumer
} from 'kafkajs';

jest.mock('kafkajs');

jest.spyOn(console, 'log').mockImplementation(() => {});
jest.spyOn(console, 'warn').mockImplementation(() => {});
jest.spyOn(console, 'error').mockImplementation(() => {});

describe('KafkaService', () => {

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('initKafka', () => {
    it('should connect the producer and return true on success', async () => {
      // Arrange
      mockProducerConnect.mockResolvedValue(true);

      // Act
      const result = await initKafka();

      // Assert
      expect(mockProducerConnect).toHaveBeenCalledTimes(1);
      expect(result).toBe(true);
      expect(console.warn).not.toHaveBeenCalled();
    });

    it('should fail to connect and return false on error', async () => {
      // Arrange
      const connectionError = new Error('Connection timed out');
      mockProducerConnect.mockRejectedValue(connectionError);

      // Act
      const result = await initKafka();

      // Assert
      expect(mockProducerConnect).toHaveBeenCalledTimes(1);
      expect(result).toBe(false);
      expect(console.warn).toHaveBeenCalledWith(expect.stringContaining('Failed to connect to Kafka'), connectionError.message);
    });
  });

  describe('sendMessage', () => {
    const topic = TOPICS.RESIDENT_MESSAGES;
    const message = { senderId: 'user1', receiverId: 'user2', content: 'Hello!' };

    it('should send a message successfully and return true', async () => {
      // Arrange
      mockProducerSend.mockResolvedValue([{ topicName: topic, partition: 0 }]);
      
      // Act
      const result = await sendMessage(topic, message);

      // Assert
      expect(mockProducerSend).toHaveBeenCalledTimes(1);
      expect(mockProducerSend).toHaveBeenCalledWith({
        topic,
        messages: [{ value: JSON.stringify(message), key: 'user1-user2' }],
      });
      expect(result).toBe(true);
    });

    it('should construct the correct key for a broadcast message', async () => {
      // Arrange
      const broadcastMessage = { ...message, isBroadcast: true };
      mockProducerSend.mockResolvedValue(true);
      
      // Act
      await sendMessage(topic, broadcastMessage);

      // Assert
      expect(mockProducerSend).toHaveBeenCalledWith(expect.objectContaining({
        messages: [expect.objectContaining({ key: 'broadcast-user1' })],
      }));
    });

    it('should throw an error if the topic is invalid', async () => {
      // Arrange
      const invalidTopic = null;

      // Act & Assert
      await expect(sendMessage(invalidTopic, message)).rejects.toThrow('Invalid topic');
      expect(mockProducerSend).not.toHaveBeenCalled();
    });

    it('should re-throw an error if the producer fails to send', async () => {
      // Arrange
      const sendError = new Error('KafkaJS request timed out');
      mockProducerSend.mockRejectedValue(sendError);

      // Act & Assert
      await expect(sendMessage(topic, message)).rejects.toThrow(sendError);
      expect(console.error).toHaveBeenCalledWith(expect.stringContaining(`Error sending message to topic ${topic}`), sendError);
    });

    it('should throw a timeout error if producer.send takes too long', async () => {
      // Arrange
      mockProducerSend.mockImplementation(() => new Promise(() => {}));

      // Act & Assert
      await expect(sendMessage(topic, message)).rejects.toThrow('Kafka send timeout');
    });
  });

  describe('createConsumer', () => {
    it('should call the kafka.consumer method with the correct groupId', () => {
      // Arrange
      const groupId = 'test-group-1';
      const mockConsumerInstance = { connect: jest.fn(), subscribe: jest.fn() };
      mockConsumer.mockReturnValue(mockConsumerInstance);
      
      // Act
      const consumer = createConsumer(groupId);

      // Assert
      expect(mockConsumer).toHaveBeenCalledTimes(1);
      expect(mockConsumer).toHaveBeenCalledWith({ groupId });
      expect(consumer).toBe(mockConsumerInstance);
    });
  });
});