import { Model, DataTypes } from 'sequelize';
import { sequelize } from '../../infrastructure/database.js';

class Message extends Model {}

Message.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    content: {
      type: DataTypes.TEXT,
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    image: {
      type: DataTypes.BLOB('long'),
      allowNull: true,
    },
    image_mime_type: {
      type: DataTypes.STRING,
      allowNull: true,
      validate: {
        isValidImageType(value) {
          if (value && !['image/jpeg', 'image/jpg', 'image/png'].includes(value)) {
            throw new Error('Apenas imagens nos formatos JPEG e PNG são aceitas');
          }
        }
      }
    },
    image_filename: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    is_read: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    created_at: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
  },
  {
    sequelize,
    modelName: 'Message',
    tableName: 'message',
    timestamps: false,
    hooks: {
      beforeValidate: (message) => {
        if (message.image_mime_type && !message.image) {
          message.image_mime_type = null;
          message.image_filename = null;
        }
        if (message.image && !message.image_mime_type) {
          throw new Error('Tipo de imagem não especificado');
        }
      }
    }
  }
);

export default Message;