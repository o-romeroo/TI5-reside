import express from 'express'
import swaggerUi from 'swagger-ui-express';
import { initDatabase } from './src/infrastructure/database.js'; 
import YAML from 'yamljs';
import './src/core/models/index.js'; 
import condominiumRoutes from './src/presentation/routes/condominium_route.js';
import inviteRoutes from './src/presentation/routes/invite_route.js';
import residentRoutes from './src/presentation/routes/resident_route.js';
import cors from 'cors';
import admin from 'firebase-admin';
import { createRequire } from 'module';
import { initKafka } from './src/core/services/kafka_service.js';
import messageRoutes from './src/presentation/routes/message_route.js';
import amenityRoutes from './src/presentation/routes/amenity_route.js';
import bookingRoutes from './src/presentation/routes/booking_route.js';
import parkingRoutes from './src/presentation/routes/parking_route.js';
import { startParkingExpirationJob } from './src/core/jobs/parking_expiration_job.js';
import requestRoutes from './src/presentation/routes/request_route.js';
import notificationRoutes from './src/presentation/routes/notification_route.js';

const require = createRequire(import.meta.url);
const serviceAccount = require('./src/config/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});


const app = express();
const swaggerDocument = YAML.load('./src/config/swagger.yaml');

app.use(express.urlencoded({ extended: true }));
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));


initDatabase();

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
app.use('/condos', condominiumRoutes);
app.use('/messages', messageRoutes);
app.use('', inviteRoutes);
app.use('', residentRoutes);
app.use('', amenityRoutes);
app.use('', bookingRoutes);
app.use('', parkingRoutes);
app.use('', requestRoutes);
app.use('/notifications', notificationRoutes);



const startServer = async () => {
  try {
    await initKafka();

    // Iniciar o job de verificação de reservas expiradas
    startParkingExpirationJob();
    
    app.listen(process.env.PORT, '0.0.0.0', () => {
      console.log(`Servidor rodando em http://localhost:${process.env.PORT}`);
      console.log(`Documentação disponível em http://localhost:${process.env.PORT}/api-docs`);
      console.log(`Kafka API disponível em http://kafka-broker.railway.internal:9092`);
    });
  } catch (error) {
    console.error('Failed to initialize Kafka:', error);
    process.exit(1);
  }
};

startServer();

export default admin