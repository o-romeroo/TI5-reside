import parkingRepository from "../../infrastructure/repositories/parking_repository.js";
import residentRepository from "../../infrastructure/repositories/resident_repository.js";

class ParkingService {
  async createParking(parkingData) {
    try {
      this.validateParkingData(parkingData);

      const resident = await residentRepository.findById(parkingData.resident_id);
      if (!resident) {
        throw new Error('Residente não encontrado');
      }

      const condoResidents = await residentRepository.findAllByCondo(parkingData.condominium_id);
      const apartmentExists = condoResidents.some(r => r.apartment === parkingData.apartment);

      if (!apartmentExists) {
        throw new Error('Apartamento não encontrado no condomínio');
      }

      const parkingCount = await parkingRepository.countParkingsByApartment(
        parkingData.apartment,
        parkingData.condominium_id
      );

      if (parkingCount >= 2) {
        throw new Error('Limite excedido: um apartamento pode ter no máximo 2 vagas');
      }

      if (parkingData.type === 'diario') {
        const availableDate = new Date(parkingData.available_date);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        availableDate.setHours(0, 0, 0, 0);

        if (availableDate < today) {
          throw new Error('Não é possível criar vagas para datas passadas');
        }
      }

      return await parkingRepository.create(parkingData);
    } catch (error) {
      throw error;
    }
  }

  validateParkingData(data) {
    if (!data.location) {
      throw new Error('Localização da vaga é obrigatória');
    }

    if (!data.apartment) {
      throw new Error('Número do apartamento é obrigatório');
    }

    if (!data.type || !['diario', 'mensal'].includes(data.type)) {
      throw new Error('Tipo de aluguel inválido');
    }

    if (!data.price || data.price <= 0) {
      throw new Error('Preço inválido');
    }

    if (data.is_covered === undefined) {
      throw new Error('Informe se a vaga é coberta ou descoberta');
    }

    if (data.type === 'diario') {
      if (!data.available_date) {
        throw new Error('Data disponível é obrigatória para vagas diárias');
      }
      if (!data.start_time || !data.end_time) {
        throw new Error('Horários de início e fim são obrigatórios para vagas diárias');
      }

      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const availableDate = new Date(data.available_date);
      availableDate.setHours(0, 0, 0, 0);

      if (availableDate < today) {
        throw new Error('Data disponível não pode ser no passado');
      }

      if (data.start_time === data.end_time) {
        throw new Error('Horários de início e fim não podem ser iguais');
      }

    } else if (data.type === 'mensal') {
      const weekdays = ['domingo', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado'];
      const weekdaysEnglish = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];

      const hasAtLeastOneDayPt = weekdays.some(day => data[day] === true);
      const hasAtLeastOneDayEn = weekdaysEnglish.some(day => data[day] === true);

      if (!hasAtLeastOneDayPt && !hasAtLeastOneDayEn) {
        throw new Error('Pelo menos um dia da semana deve ser selecionado');
      }

      if (hasAtLeastOneDayEn) {
        weekdaysEnglish.forEach((englishDay, index) => {
          if (data[englishDay] === true) {
            data[weekdays[index]] = true;
          }
        });
      }
    }
  }

  async getAllParkings() {
    return await parkingRepository.findAll();
  }

  async getParkingById(id) {
    return await parkingRepository.findById(id);
  }

  async getParkingsByResidentId(residentId) { 
    const parkings = await parkingRepository.findByResidentId(residentId);
    return parkings.map(parking => this.formatParkingResponse(parking));
  }

  async getParkingsByApartment(apartment, condominiumId) {
    return await parkingRepository.findByApartment(apartment, condominiumId);
  }

  async getParkingsByCondominiumId(condominiumId) {
    return await parkingRepository.findByCondominiumId(condominiumId);
  }

  async findAvailableParkings(filters) {
    return await parkingRepository.findAvailableParkings(filters);
  }

  async updateParking(id, parkingData) {
    try {
      const parking = await parkingRepository.findById(id);
      if (!parking) {
        throw new Error('Vaga não encontrada');
      }

      if (parkingData.apartment &&
        parkingData.apartment !== parking.apartment) {

        const parkingCount = await parkingRepository.countParkingsByApartment(
          parkingData.apartment,
          parking.condominium_id
        );

        if (parkingCount >= 2) {
          throw new Error('Limite excedido: um apartamento pode ter no máximo 2 vagas');
        }
      }

      if (parkingData.type) {
        this.validateParkingData({ ...parking, ...parkingData });
      }

      return await parkingRepository.update(id, parkingData);
    } catch (error) {
      throw error;
    }
  }

  async deleteParking(id) {
    try {
      const parking = await parkingRepository.findById(id);
      if (!parking) {
        throw new Error('Vaga não encontrada');
      }

      return await parkingRepository.delete(id);
    } catch (error) {
      throw error;
    }
  }

  async requestParking(parkingId, residentId) {
    try {
      const parking = await parkingRepository.findById(parkingId);
      if (!parking) {
        throw new Error('Vaga não encontrada');
      }

      if (parking.type === 'diario') {
        const availableDate = new Date(parking.available_date);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        availableDate.setHours(0, 0, 0, 0);

        if (availableDate < today) {
          throw new Error('Esta vaga diária já expirou');
        }
      }

      if (parking.status !== 'disponivel') {
        throw new Error('Vaga não está disponível');
      }

      const resident = await residentRepository.findById(residentId);
      if (!resident) {
        throw new Error('Residente não encontrado');
      }

      const expirationTime = new Date();

      if (parking.type === 'diario') {
        const availableDate = new Date(parking.available_date);
        const [endHour, endMinute] = parking.end_time.split(':').map(Number);

        const endDateTime = new Date(availableDate);
        endDateTime.setHours(endHour, endMinute, 0, 0);

        const now = new Date();
        if (endDateTime < now) {
          expirationTime.setHours(expirationTime.getHours() + 24);
        } else {
          expirationTime.setTime(endDateTime.getTime());
        }
      } else {
        const availableMonthlyDate = new Date(parking.available_date);
        expirationTime.setDate(availableMonthlyDate.getDate() + 30);
      }

      await parkingRepository.reserveParking(parkingId, residentId, expirationTime);

      return {
        message: 'Solicitação de vaga realizada com sucesso',
        expiresAt: expirationTime
      };
    } catch (error) {
      throw error;
    }
  }

  async cancelRequest(parkingId) {
    try {
      const parking = await parkingRepository.findById(parkingId);
      if (!parking) {
        throw new Error('Vaga não encontrada');
      }

      if (parking.status !== 'reservado') {
        throw new Error('Vaga não está reservada');
      }

      await parkingRepository.cancelReservation(parkingId);

      return { message: 'Solicitação de vaga cancelada com sucesso' };
    } catch (error) {
      throw error;
    }
  }

  async checkExpiredReservations() {
    try {
      const expiredReservations = await parkingRepository.findExpiredReservations();

      let canceledCount = 0;
      for (const reservation of expiredReservations) {
        await parkingRepository.cancelReservation(reservation.id);
        canceledCount++;
      }

      const expiredDailyResult = await this.checkExpiredDailyParkings();

      return {
        message: `${canceledCount} reservas expiradas foram canceladas e ${expiredDailyResult.deletedCount} vagas diárias expiradas foram excluídas`,
        canceledCount,
        deletedDailyParkings: expiredDailyResult.deletedCount
      };
    } catch (error) {
      throw error;
    }
  }

  async checkExpiredDailyParkings() {
    try {
      const expiredParkings = await parkingRepository.findExpiredDailyParkings();

      let deletedCount = 0;
      for (const parking of expiredParkings) {
        await parkingRepository.delete(parking.id);
        deletedCount++;
      }

      return {
        message: `${deletedCount} vagas diárias expiradas foram excluídas`,
        deletedCount
      };
    } catch (error) {
      throw error;
    }
  }

  formatParkingResponse(parkingInstance) {
    if (!parkingInstance) return null;
    const parking = parkingInstance.get({ plain: true });

    const formattedParking = { ...parking }; 

    if (parking.owner) { 
      formattedParking.owner_name = `${parking.owner.first_name || ''} ${parking.owner.last_name || ''}`.trim();
      formattedParking.owner_details = {
          id: parking.owner.id,
          apartment: parking.owner.apartment,
          contact_phone: parking.owner.contact_phone
      };
      delete formattedParking.owner;
    } else if (formattedParking.resident_id && !formattedParking.owner_name) {
    }


    if (parking.reserver) { 
        formattedParking.reserver_name = `${parking.reserver.first_name || ''} ${parking.reserver.last_name || ''}`.trim();
        formattedParking.reserver_details = {
            id: parking.reserver.id,
            contact_phone: parking.reserver.contact_phone,
            apartment: parking.reserver.apartment,
        };
        delete formattedParking.reserver; 
    } else {
        formattedParking.reserver_name = null; 
    }

    return formattedParking;
  }

  async getReservationsByResidentId(residentId) {
    try {
      const reservations = await parkingRepository.findReservationsByResidentId(residentId);
      return reservations.map(reservation => this.formatParkingResponse(reservation));
    } catch (error) {
      throw error;
    }
  }
}
export default new ParkingService();