import BaseRepository from '/src/infrastructure/repositories/base_repository.js';
import { Request } from '/src/core/models/index.js';

class RequestRepository extends BaseRepository {
  constructor() { super(Request); }
}
