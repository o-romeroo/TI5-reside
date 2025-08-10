import cron from 'node-cron';
import ParkingService from '../services/parking_service.js';

// Verifica reservas e vagas expiradas a cada 15 minutos
export function startParkingExpirationJob() {
  console.log('Iniciando job de verificação de expiração...');
  
  cron.schedule('*/15 * * * *', async () => {
    try {
      console.log('Executando verificação de reservas e vagas expiradas...');
      
      // Verificar reservas expiradas
      const result = await ParkingService.checkExpiredReservations();
      
      console.log(`${result.canceledCount} reservas expiradas foram canceladas`);
      console.log(`${result.deletedDailyParkings} vagas diárias expiradas foram excluídas`);
    } catch (error) {
      console.error('Erro ao verificar expiração:', error);
    }
  });
}