class RequestService {
  constructor(requestRepository) {
    this.requestRepository = requestRepository;
  }

  async getRequestsByResidentId(residentId) {
    return this.requestRepository.getAll({
      where: { resident_id: residentId },
      include: ['resident', 'condominium'],
    });
  }

  async getRequestById(requestId) {
    return this.requestRepository.getById(requestId, { include: ['resident', 'condominium'] });
  }

  async createRequest(requestData) {
    if (!requestData.resident_id || !requestData.type || !requestData.description) {
      throw new Error('Missing required fields for request');
    }
    
    requestData.status = 'open';
    requestData.created_at = new Date();
    return this.requestRepository.create(requestData);
  }

  async updateRequest(requestId, requestData) {
    if (!requestData) {
      throw new Error('No update data provided');
    }
    
    if (requestData.status && (requestData.status === 'closed' || requestData.status === 'resolved')) {
      requestData.closed_at = new Date();
    }
    
    return this.requestRepository.update(requestId, requestData);
  }
}
export default RequestService;