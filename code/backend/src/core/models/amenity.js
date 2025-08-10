import { Model, DataTypes } from 'sequelize';
import { sequelize } from '../../infrastructure/database.js';
import Condominium from './condominium.js';

class Amenity extends Model {}

Amenity.init(
  {
    id: {
      type: DataTypes.BIGINT,
      autoIncrement: true,
      primaryKey: true,
    },
    condominium_id: {
      type: DataTypes.BIGINT,
      allowNull: false,
      references: {
        model: Condominium,
        key: 'id',
      },
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    capacity: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
  },
  {
    sequelize,
    modelName: 'Amenity',
    tableName: 'amenities',
    timestamps: true,
  }
);

export default Amenity;