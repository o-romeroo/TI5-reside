import { Model, DataTypes } from 'sequelize';
import { sequelize } from '../../infrastructure/database.js';


class Condominium extends Model {}

Condominium.init(
  {
    id: {
      type: DataTypes.BIGINT,
      autoIncrement: true,
      primaryKey: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    address: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        notEmpty: true,
      },
    },
    vector_store_id: {
      type: DataTypes.STRING,
      allowNull: true,
      comment: 'ID do vector store da OpenAI',
    },
     rules_file_id: {
      type: DataTypes.STRING,
      allowNull: true,
      comment: 'ID do arquivo de regras associado à vector store',
    },
    upload_at: {
      type: DataTypes.DATE,
      allowNull: true,
      comment: 'Data de upload do arquivo de regras',
    },
    upload_filename: {
      type: DataTypes.STRING,
      allowNull: true,
      comment: 'Nome do arquivo de regras enviado',
    },
  },
  {
    sequelize,
    modelName: 'Condominium',
    tableName: 'condominium',
    timestamps: false,
  }
);

export default Condominium;
