import Invite from '../../core/models/invite.js'; // ajuste o path conforme sua estrutura
import { Op } from 'sequelize';

class InviteRepository {
  async create(data) {
    return await Invite.create(data);
  }

  async findByInviteCode(invite_code) {
    return await Invite.findOne({ where: { invite_code } });
  }

  async markAsUsed(invite_code, used_by) {
    return await Invite.update(
      {
        used: true,
        used_by,
        used_at: new Date(),
      },
      {
        where: { invite_code },
      }
    );
  }

  async findValidInvite(invite_code) {
    return await Invite.findOne({
      where: {
        invite_code,
        used: false,
        expires_at: { [Op.gt]: new Date() },
      },
    });
  }

  async getInvitesByCondo(condominium_id) {
    return await Invite.findAll({
      where: { condominium_id },
      order: [['id', 'DESC']],
    });
  }

  async delete(invite_id) {
    return await Invite.destroy({ where: { id: invite_id } });
  }
}

export default new InviteRepository();
