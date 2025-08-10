import { Model, DataTypes } from 'sequelize';
import { sequelize } from '../../infrastructure/database.js';

class Request extends Model {}

Request.init(
  {
    id: {
      type: DataTypes.BIGINT,
      autoIncrement: true,
      primaryKey: true,
    },
    title: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    type: {
      type: DataTypes.ENUM('Reclamação', 'Sugestão', 'Manutenção', 'Outros'),
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    status: {
      type: DataTypes.ENUM('open', 'closed'),
      allowNull: false,
      defaultValue: 'open',
    },
    response: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    created_at: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    closed_at: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    
    resident_id: {
        type: DataTypes.BIGINT,
        allowNull: false,
        references: {
            model: 'resident',
            key: 'id',
        },
    }
  },
  {
    sequelize,
    modelName: 'Request',
    tableName: 'request',
    timestamps: false,
  }
);

export default Request;