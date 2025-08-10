import BaseRepository from './base_repository.js';
import Condominium   from '../../core/models/condominium.js'; // Assuming index.js exports an object with models

class CondominiumRepository extends BaseRepository {
  constructor() { 
    super(Condominium); 
  }

  async update(id, updateData) {
    return await super.update(id, updateData);
  }

  async getById(id, options = {}) {
    return await super.getById(id, options);
  }

}
export default new CondominiumRepository();
