import BaseRepository from './base_repository.js';
import Parking from '../../core/models/parking.js';
import { Op } from 'sequelize';
import Resident from '../../core/models/resident.js';

class ParkingRepository extends BaseRepository {
  constructor() {
    super(Parking);
  }

  async findById(id) {
    return await this.model.findByPk(id, {
      include: [
        {
          model: Resident,
          as: 'owner',
          attributes: ['id', 'first_name', 'last_name', 'email', 'contact_phone', 'apartment']
        },
        {
          model: Resident,
          as: 'reserver',
          attributes: ['id', 'first_name', 'last_name', 'email', 'contact_phone', 'apartment']
        }
      ]
    });
  }

  async findAll() {
    return await this.model.findAll({
      include: [
        {
          model: Resident,
          as: 'owner',
          attributes: ['id', 'first_name', 'last_name', 'email', 'contact_phone', 'apartment']
        },
        {
          model: Resident,
          as: 'reserver',
          attributes: ['id', 'first_name', 'last_name', 'email', 'contact_phone', 'apartment']
        }
      ],
      order: [['createdAt', 'DESC']]
    });
  }

  async findByResidentId(residentId) {
    return await this.model.findAll({
      where: { resident_id: residentId },
      include: [
        {
          model: Resident,
          as: 'reserver', 
          attributes: ['id', 'first_name', 'last_name', 'email', 'contact_phone', 'apartment'],
          required: false 
        }
      ],
      order: [['createdAt', 'DESC']]
    });
  }
  
  async findByApartment(apartment, condominiumId) {
    return await this.model.findAll({
      where: {
        apartment: apartment,
        condominium_id: condominiumId
      },
      order: [['createdAt', 'DESC']]
    });
  }

  async countParkingsByApartment(apartment, condominiumId) {
    return await this.model.count({
      where: {
        apartment: apartment,
        condominium_id: condominiumId
      }
    });
  }

  async findByCondominiumId(condominiumId) {
    return await this.model.findAll({
      where: { condominium_id: condominiumId },
      order: [['createdAt', 'DESC']]
    });
  }

  async findAvailableParkings(filters) {
    const where = {
      status: 'disponivel',
      condominium_id: filters.condominiumId,
    };

    // Filtro por localização
    if (filters.location) {
      where.location = {
        [Op.like]: `%${filters.location}%`
      };
    }

    // Filtro por preço máximo
    if (filters.maxPrice) {
      where.price = {
        [Op.lte]: filters.maxPrice
      };
    }

    // Filtro por tipo de vaga (coberta/descoberta)
    if (filters.isCovered !== undefined) {
      where.is_covered = filters.isCovered;
    }

    // Filtro por tipo
    if (filters.type) {
      where.type = filters.type;

      // Filtros específicos para vagas diárias
      if (filters.type === 'diario' && filters.date) {
        where.available_date = filters.date;

        // Filtro por hora de início e fim
        if (filters.startTime && filters.endTime) {
          // Garante que a vaga está disponível durante todo o período solicitado
          where.start_time = {
            [Op.lte]: filters.startTime
          };
          where.end_time = {
            [Op.gte]: filters.endTime
          };
        }
      }
      // Filtros específicos para vagas mensais
      else if (filters.type === 'mensal' && filters.weekdays) {
        // Filtro para dias da semana específicos
        const weekdayFields = ['domingo', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado'];

        filters.weekdays.forEach((selected, index) => {
          if (selected) {
            where[weekdayFields[index]] = true;
          }
        });
      }
    }

    return await this.model.findAll({
      where,
      include: [{
        model: Resident,
        as: 'owner',
        attributes: ['id', 'first_name', 'last_name', 'email', 'contact_phone', 'apartment']
      }],
      order: [['createdAt', 'DESC']]
    });
  }

  async reserveParking(parkingId, residentId, expiresAt) {
    return await this.model.update(
      {
        status: 'reservado',
        reserver_id: residentId,
        reservation_expires_at: expiresAt
      },
      {
        where: { id: parkingId }
      }
    );
  }

  async cancelReservation(parkingId) {
    return await this.model.update(
      {
        status: 'disponivel',
        reserver_id: null,
        reservation_expires_at: null
      },
      {
        where: { id: parkingId }
      }
    );
  }

  async findExpiredReservations() {
    const now = new Date();
    return await this.model.findAll({
      where: {
        status: 'reservado',
        reservation_expires_at: {
          [Op.lt]: now
        }
      }
    });
  }

  async findReservationsByResidentId(residentId) {
    return await this.model.findAll({
      where: {
        reserver_id: residentId,
        status: 'reservado'
      },
      include: [
        {
          model: Resident,
          as: 'owner',
          attributes: ['id', 'first_name', 'last_name', 'email', 'contact_phone', 'apartment']
        },
        { 
          model: Resident,
          as: 'reserver', 
          attributes: ['id', 'first_name', 'last_name', 'email', 'contact_phone', 'apartment']
        }
      ],
      order: [['reservation_expires_at', 'DESC']]
    });
  }

  async findExpiredDailyParkings() {
    const now = new Date();

    const dailyParkings = await this.model.findAll({
      where: {
        type: 'diario',
        status: 'disponivel'
      }
    });

    return dailyParkings.filter(parking => {
      const availableDate = new Date(parking.available_date);
      const [endHour, endMinute] = parking.end_time.split(':').map(Number);

      availableDate.setHours(endHour, endMinute, 0, 0);

      return availableDate < now;
    });
  }
}

export default new ParkingRepository();