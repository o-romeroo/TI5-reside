import Condominium from './condominium.js';
import Resident from './resident.js';
import Request from './request.js';
import Message from './message.js';
import Amenity from './amenity.js';
import Booking from './booking.js';
import Parking from './parking.js';
import Invite from './invite.js';

Condominium.hasMany(Resident, {
  foreignKey: {
    name: 'condominium_id',
    allowNull: false,
  },
  as: 'residents',
});

Resident.belongsTo(Condominium, {
  foreignKey: {
    name: 'condominium_id',
    allowNull: true,
  },
  as: 'condominium',
});

Condominium.hasMany(Request, {
  foreignKey: {
    name: 'condominium_id',
    allowNull: false,
  },
  as: 'requests',
});

Request.belongsTo(Condominium, {
  foreignKey: {
    name: 'condominium_id',
    allowNull: false,
  },
  as: 'condominium',
});

Resident.hasMany(Request, {
  foreignKey: {
    name: 'resident_id',
    allowNull: false,
  },
  as: 'requests',
});

Request.belongsTo(Resident, {
  foreignKey: {
    name: 'resident_id',
    allowNull: false,
  },
  as: 'creator',
});

Resident.hasMany(Message, {
  foreignKey: {
    name: 'sender_id',
    allowNull: false,
  },
  as: 'sentMessages',
});

Message.belongsTo(Resident, {
  foreignKey: {
    name: 'sender_id',
    allowNull: false,
  },
  as: 'sender',
});

Resident.hasMany(Message, {
  foreignKey: {
    name: 'receiver_id',
    allowNull: false,
  },
  as: 'receivedMessages',
});

Message.belongsTo(Resident, {
  foreignKey: {
    name: 'receiver_id',
    allowNull: false,
  },
  as: 'receiver',
});

Amenity.hasMany(Booking, { 
  foreignKey: 'amenity_id',
  as: 'bookings' 
});

Booking.belongsTo(Amenity, { 
  foreignKey: 'amenity_id',
  as: 'amenity' 
});

Resident.hasMany(Booking, { 
  foreignKey: 'resident_id',
  as: 'bookings'
});

Booking.belongsTo(Resident, { 
  foreignKey: 'resident_id',
  as: 'resident'
});

Resident.hasMany(Parking, {
  foreignKey: {
    name: 'resident_id',
    allowNull: false,
  },
  as: 'parkingSpots',
});

Parking.belongsTo(Resident, {
  foreignKey: {
    name: 'resident_id',
    allowNull: false,
  },
  as: 'owner',
});

Resident.hasMany(Parking, {
  foreignKey: {
    name: 'reserver_id',
    allowNull: true,
  },
  as: 'reservedParkings',
});

Parking.belongsTo(Resident, {
  foreignKey: {
    name: 'reserver_id',
    allowNull: true,
  },
  as: 'reserver',
});

Condominium.hasMany(Parking, {
  foreignKey: {
    name: 'condominium_id',
    allowNull: false,
  },
  as: 'parkingSpots',
});

Parking.belongsTo(Condominium, {
  foreignKey: {
    name: 'condominium_id',
    allowNull: false,
  },
  as: 'condominium',
});

Invite.belongsTo(Condominium, {
  foreignKey: {
    name: 'condominium_id',
    allowNull: false
  },
  as: 'condominium',
});

Condominium.hasMany(Invite, {
  foreignKey: {
    name: 'condominium_id',
    allowNull: false
  },
  as: 'invites',
})

export default {
  Condominium,
  Resident,
  Request,
  Message,
  Amenity,
  Booking,
  Parking,
  Invite
};
