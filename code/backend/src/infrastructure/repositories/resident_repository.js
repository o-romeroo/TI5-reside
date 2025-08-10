import Resident from '../../core/models/resident.js';

class ResidentRepository {
  async create(data) {
    return await Resident.create(data);
  }

  async findById(id) {
    return await Resident.findByPk(id);
  }

  async findByEmail(email) {
    return await Resident.findOne({ where: { email } });
  }

  async findAllByCondo(condominium_id) {
    return await Resident.findAll({ where: { condominium_id } });
  }

  async update(id, data) {
    // Retorna [n, [updatedRows]]
    return await Resident.update(data, {
      where: { id },
      returning: true,
    });
  }

  async updateFcmToken(googleId, fcmToken) {
    return await Resident.update(
      { fcm_token: fcmToken },
      {
        where: { google_id: googleId },
        returning: true,
      }
    );
  }

  async findByGoogleId(googleId, options = {}) {
    try {
      const resident = await Resident.findOne({
        where: { google_id: googleId },
        ...options,
      });
      return resident;
    } catch (error) {
      console.error(`Error finding resident by googleId ${googleId}:`, error);
      throw error;
    }
  }

  async delete(id) {
    return await Resident.destroy({ where: { id } });
  }
}

export default new ResidentRepository();
