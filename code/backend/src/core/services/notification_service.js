import admin from 'firebase-admin';
import residentRepository from '../../infrastructure/repositories/resident_repository.js';

class NotificationService {
  
  async sendParkingRentedNotification(spotOwnerId, spotInfo, renterName) {
    try {
      // Busca o residente proprietário da vaga
      const owner = await residentRepository.findById(spotOwnerId);
      
      if (!owner || !owner.fcm_token) {
        console.log(`❌ Token FCM não encontrado para o residente ${spotOwnerId}`);
        return false;
      }

      // MUDANÇA: Usar apartment ao invés do ID da vaga
      const message = {
        token: owner.fcm_token,
        notification: {
          title: 'Vaga Alugada! 🎉',
          body: `Parabéns! Sua vaga ${spotInfo.apartment} foi alugada por ${renterName}.`,
        },
        data: {
          type: 'parking_rented',
          spotId: String(spotInfo.id), // ID da vaga para referência interna
          apartment: String(spotInfo.apartment), // NOVO: Número do apartamento
          location: String(spotInfo.location), // NOVO: Localização da vaga
          renterId: String(renterName),
        },
        android: {
          notification: {
            channelId: 'high_importance_channel',
            priority: 'high',
          },
        },
      };

      // Envia a notificação
      const response = await admin.messaging().send(message);
      console.log('✅ Notificação enviada com sucesso:', response);
      return true;

    } catch (error) {
      console.error('❌ Erro ao enviar notificação:', error);
      return false;
    }
  }

  async sendGeneralNotification(residentId, title, body, data = {}) {
    try {
      const resident = await residentRepository.findById(residentId);
      
      if (!resident || !resident.fcm_token) {
        console.log(`❌ Token FCM não encontrado para o residente ${residentId}`);
        return false;
      }

      const message = {
        token: resident.fcm_token,
        notification: { title, body },
        data,
        android: {
          notification: {
            channelId: 'high_importance_channel',
            priority: 'high',
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log('✅ Notificação geral enviada:', response);
      return true;

    } catch (error) {
      console.error('❌ Erro ao enviar notificação geral:', error);
      return false;
    }
  }
}

export default new NotificationService();