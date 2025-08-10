import condominiumRepository from '../../infrastructure/repositories/condominium_repository.js';

class CondominiumService {


  async getCondominiumById(condominiumId) {
    return condominiumRepository.getById(condominiumId, {
      include: ['name', 'address', 'residents', 'requests']
    });
  }

  async getCondominiumNameById(id) {
  const condo = await condominiumRepository.getById(id, {
    attributes: ['name']
  });

  return condo ? { name: condo.name } : null;
}



  async getAllCondominiums() {
    return condominiumRepository.getAll({
      include: ['address', 'residents', 'requests']
    });
  }

  async updateCondominium(condominiumId, updateData) {
    if (!updateData) {
      throw new Error('No update data provided');
    }
    return condominiumRepository.update(condominiumId, updateData);
  }

  async getCondomiumFileInfo(condominiumId) {
    const condo = await condominiumRepository.getById(condominiumId, {
      attributes: ['upload_filename', 'upload_at'],
    });

    if (!condo || !condo.upload_at || !condo.upload_filename) {
      throw new Error('Condomínio não encontrado ou sem arquivo de regras');
    }

    return {
      upload_filename: condo.upload_filename,
      upload_at: condo.upload_at,
    };
  }
}

export default new CondominiumService();