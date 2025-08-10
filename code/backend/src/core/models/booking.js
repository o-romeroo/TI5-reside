import { Model, DataTypes } from 'sequelize';
import { sequelize } from '../../infrastructure/database.js';
import Amenity from './amenity.js';
import Resident from './resident.js';

class Booking extends Model {}

Booking.init(
  {
    id: {
      type: DataTypes.BIGINT,
      autoIncrement: true,
      primaryKey: true,
    },
    amenity_id: {
      type: DataTypes.BIGINT,
      allowNull: false,
      references: {
        model: Amenity,
        key: 'id',
      },
    },
    resident_id: {
      type: DataTypes.BIGINT,
      allowNull: false,
      references: {
        model: Resident,
        key: 'id',
      },
    },
    start_time: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    end_time: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    status: {
      type: DataTypes.ENUM('confirmed', 'pending', 'cancelled'),
      defaultValue: 'confirmed',
      allowNull: false,
    },
  },
  {
    sequelize,
    modelName: 'Booking',
    tableName: 'bookings',
    timestamps: true,
  }
);

export default Booking;