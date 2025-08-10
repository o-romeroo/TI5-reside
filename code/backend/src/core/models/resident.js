import { Model, DataTypes } from 'sequelize';
import { sequelize } from '../../infrastructure/database.js';

class Resident extends Model {}

Resident.init(
  {
    id: {
      type: DataTypes.BIGINT,
      autoIncrement: true,
      primaryKey: true,
    },
    first_name: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        notEmpty: true,
      },
    },
    last_name: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        notEmpty: true,
      },
    },
    document: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        notEmpty: true,
      },
    },
    apartment: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        notEmpty: true,
      },
    },
    contact_phone: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        notEmpty: true,
      },
    },
    email: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        notEmpty: true,
        isEmail: true,
      },
    },
    role: {
      type: DataTypes.ENUM('admin', 'user'),
      allowNull: true,
    },
    google_id: {
      type: DataTypes.STRING,
      allowNull: true,
      unique: true,
      validate: {
        notEmpty: true,
      },
    },
    fcm_token: {
      type: DataTypes.TEXT, // FCM tokens podem ser muito longos (até 4096 chars)
      allowNull: true,
      validate: {
        // Validação apenas se o valor não for null/undefined/vazio
        isValidFcmToken(value) {
          if (value !== null && value !== undefined && value !== '') {
            // Validação básica: FCM tokens são strings longas
            if (typeof value !== 'string' || value.length < 50) {
              throw new Error('FCM token deve ser uma string válida');
            }
          }
        }
      },
    },
    registered: {
      type: DataTypes.BOOLEAN,
      allowNull: true,
      defaultValue: false,
      validate: {
        notEmpty: true,
      },
    },
    condominium_id: {
      type: DataTypes.BIGINT,
      allowNull: true,             // permite criar stub sem vínculo
      references: {
        model: 'condominium',       // nome exato da sua tabela de condomínios
        key: 'id',
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    },
  },
    
  {
    sequelize,
    modelName: 'Resident',
    tableName: 'resident',
    timestamps: false,
  }
);



export default Resident;
