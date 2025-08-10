class BaseRepository {
  constructor(model) {
    this.model = model;
  }

  async getAll(options) {
    return this.model.findAll(options);
  }

  async getById(id, options) {
    return this.model.findByPk(id, options);
  }

  async create(data, options) {
    return this.model.create(data, options);
  }

  async update(id, data, options) {
    const entity = await this.model.findByPk(id);
    if (entity) {
      return entity.update(data, options);
    }
    return null;
  }

  async delete(id, options) {
    const entity = await this.model.findByPk(id);
    if (entity) {
      await entity.destroy(options);
      return true;
    }
    return false;
  }
}

export default BaseRepository;