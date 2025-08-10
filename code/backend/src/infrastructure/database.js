import { Sequelize } from 'sequelize';
import dotenv from 'dotenv';

dotenv.config();


const sequelize = new Sequelize(
  process.env.DB_NAME, 
  process.env.DB_USER, 
  process.env.DB_PASSWORD, 
  {
    host: process.env.DB_HOST, 
    port: process.env.DB_PORT, 
    dialect: 'postgres', 
    logging: true, 
    define:{
      timestamps: false,
    }
  },
);

const initDatabase = async () => {
    try {
      await sequelize.authenticate();
      console.log('Conexão com o banco de dados bem-sucedida!');
  
      await sequelize.sync(); 
      console.log('Tabelas criadas ou atualizadas com sucesso!');
    } catch (error) {
      console.error('Erro ao conectar ou sincronizar o banco de dados:', error);
      process.exit(1); 
    }
  };

export { sequelize, initDatabase };
