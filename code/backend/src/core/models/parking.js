import { Model, DataTypes } from 'sequelize';
import { sequelize } from '../../infrastructure/database.js';

class Parking extends Model {}

Parking.init(
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    resident_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    apartment: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    condominium_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    location: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    type: {
      type: DataTypes.ENUM('diario', 'mensal'),
      allowNull: false,
    },
    price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    status: {
      type: DataTypes.ENUM('disponivel', 'reservado', 'indisponivel'),
      defaultValue: 'disponivel',
    },
    is_covered: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    // Campos para vagas diárias
    available_date: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },
    start_time: {
      type: DataTypes.TIME,
      allowNull: true,
    },
    end_time: {
      type: DataTypes.TIME,
      allowNull: true,
    },
    // Campos para vagas mensais (dias da semana)
    domingo: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    segunda: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    terca: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    quarta: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    quinta: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    sexta: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    sabado: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    // Campos para controle de reserva
    reserver_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'resident',
        key: 'id'
      }
    },
    reservation_expires_at: {
      type: DataTypes.DATE,
      allowNull: true,
    }
  },
  {
    sequelize,
    modelName: 'Parking',
    tableName: 'parkings',
    timestamps: true,
    underscored: true,
  }
);

export default Parking;