import { Kafka } from 'kafkajs';
import dotenv from 'dotenv';

dotenv.config();

// Usar porta 9092 para conexão externa
// const brokers = ('kafka-broker.railway.internal:9092').split(',');
const brokers = ('localhost:9092').split(',');
console.log('Connecting to Kafka brokers:', brokers);

const kafka = new Kafka({
  clientId: 'reside-app',
  brokers: brokers,
  connectionTimeout: 5000,
  retry: {
    maxRetryTime: 30000,
    initialRetryTime: 300,
    retries: 5
  }
});

const producer = kafka.producer({
  allowAutoTopicCreation: true,
});

// Tópicos de mensagens
const TOPICS = {
  RESIDENT_MESSAGES: 'resident-messages',
  CONDOMINIUM_BROADCAST: 'condominium-broadcast',
  NOTIFICATIONS: 'notifications',
  CONDOMINIUM_MESSAGES: 'condominium-messages'
};

export async function initKafka() {
  try {
    await producer.connect();
    console.log('Kafka producer connected successfully to:', brokers);
    return true;
  } catch (error) {
    console.warn('Failed to connect to Kafka, continuing without messaging support:', error.message);
    return false;
  }
}

/**
 * Enviar mensagem com tratamento de falha
 */
export async function sendMessage(topic, message) {
  if (!topic) {
    console.error('Invalid topic provided:', topic);
    throw new Error('Invalid topic');
  }

  try {
    const key = message.isBroadcast 
      ? `broadcast-${message.senderId}` 
      : `${message.senderId}-${message.receiverId || 'all'}`;

    // Adicionado um timeout para não bloquear por muito tempo
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Kafka send timeout')), 2000);
    });
      
    await Promise.race([
      producer.send({
        topic,
        messages: [{ 
          value: JSON.stringify(message),
          key,
        }],
      }),
      timeoutPromise
    ]);
    
    return true;
  } catch (error) {
    console.error(`Error sending message to topic ${topic}:`, error);
    throw error;
  }
}

export function createConsumer(groupId) {
  return kafka.consumer({ groupId });
}

export { TOPICS };
