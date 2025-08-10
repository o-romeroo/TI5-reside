
import residentRepository from "../../infrastructure/repositories/resident_repository.js";
import Condominium from '../../core/models/condominium.js';
import dotenv from "dotenv";

dotenv.config();

class ResidentService {

  async checkOrCreateUser(googleId, fcm_token = null) {
    let resident = await residentRepository.findByGoogleId(googleId);

    if (!resident) {
      resident = await residentRepository.create({
        fcm_token: fcm_token, // pode ser null
        google_id: googleId,
        registered: false,
      });
    } else if (fcm_token && resident.fcm_token !== fcm_token) {
      // Atualiza o FCM token se foi fornecido e é diferente do atual
      await residentRepository.updateFcmToken(googleId, fcm_token);
      resident.fcm_token = fcm_token;
    }

    return resident;
  }

  async getUserInfoByGoogleId(googleId) {
    const resident = await residentRepository.findByGoogleId(googleId, {
      include: [{
        model: Condominium,
        as: 'condominium',
        attributes: ['name']
      }]
    });

    if (!resident) {
      throw new Error('Usuário não encontrado');
    }

    return {
      role: resident.role,
      id: resident.id,
      condominium_id: resident.condominium_id,
      first_name: resident.first_name,
      last_name: resident.last_name,
      apartment: resident.apartment,
      condominium_name: resident.condominium ? resident.condominium.name : null,
      fcm_token: resident.fcm_token || null,
    };
  }


  async getResidentById(residentId) {
    return residentRepository.getById(residentId, {
      include: ['requests']
    });
  }

  async createResident(residentData) {
    if (!residentData.name || !residentData.condominium_id) {
      throw new Error('Missing required fields for resident');
    }
    return residentRepository.create(residentData);
  }

  async updateResident(residentId, residentData) {
    if (!residentData) {
      throw new Error('No update data provided');
    }
    return residentRepository.update(residentId, residentData);
  }


}

export default new ResidentService();