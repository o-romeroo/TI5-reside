import inviteRepository from "../../infrastructure/repositories/invite_repository.js";
import residentRepository from "../../infrastructure/repositories/resident_repository.js"; 
import { v4 as uuidv4 } from "uuid";
import nodemailer from "nodemailer";
import dayjs from "dayjs";
import dotenv from "dotenv";



dotenv.config();

class InviteService {
  // 1. Gera um código alfanumérico único de 8 caracteres
  async generateUniqueCode() {
    let code;
    let exists = true;
    while (exists) {
      code = uuidv4().replace(/-/g, "").substring(0, 8);
      const invite = await inviteRepository.findByInviteCode(code);
      exists = !!invite;
    }
    return code;
  }

  // 2. Envia e-mails de convite
  async sendInviteEmails(
    emailList,
    { apartment, condominium_id, expires_in_days = 3 }
  ) {
    const invites = [];
    for (const email of emailList) {
      const code = await this.generateUniqueCode();
      const expires_at = dayjs().add(expires_in_days, "days").toDate();

      // Cria convite no banco
      const invite = await inviteRepository.create({
        resident_email: email,
        apartment,
        condominium_id,
        invite_code: code,
        expires_at,
        used: false,
        used_by: null,
        used_at: null,
      });

      // Envia email
      await this.sendEmail(email, code);
      invites.push(invite);
    }
    return invites;
  }

  async sendEmail(email, code) {
    const transporter = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: {
        user: "mobile.reside@gmail.com",
        pass: process.env.EMAIL_PASSWORD,
      },
    });

    const info = await transporter.sendMail({
      from: '"Seu Condomínio" <mobile.reside@gmail.com>',
      to: email,
      subject: "Convite para acessar o aplicativo do condomínio",
      html: `
        <div style="font-family: Arial, sans-serif; text-align: center; padding: 40px; background-color: #f7f7f7;">
          <div style="max-width: 600px; margin: auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1);">
            <h2 style="color:rgb(54, 146, 250);">Bem-vindo ao Reside!</h2>
            <p style="font-size: 16px; color: #333;">Olá!</p>
            <p style="font-size: 16px; color: #333;">
              Você foi convidado para acessar o aplicativo do seu condomínio.
            </p>
            <p style="font-size: 18px; font-weight: bold; color: rgb(54, 146, 250); margin: 20px 0;">Código de Acesso:</p>
            <div style="font-size: 24px; font-weight: bold; background-color: rgb(174, 212, 255);; padding: 10px 20px; display: inline-block; border-radius: 5px;">
              ${code}
            </div>
            <p style="margin-top: 30px; font-size: 14px; color: #777;">
              Caso não tenha solicitado este acesso, por favor ignore este e-mail.
            </p>
          </div>
        </div>
      `,
    });


    return info;
  }

  async bindResidentToCondo(
    invite_code,
    { first_name, last_name, document, contact_phone, fcm_token, google_id }
  ) {
    // 1) Busca e valida o invite
    const invite = await inviteRepository.findValidInvite(invite_code);
    if (!invite) {
      throw new Error("Código inválido ou expirado.");
    }

    // 2) Tenta buscar o stub existente
    let resident = await residentRepository.findByGoogleId(google_id);

    // 3) Se não existir (caso raro), cria um stub mínimo
    if (!resident) {
      resident = await residentRepository.create({
        fcm_token,
        google_id,
        registered: false,
      });
    }

    // 4) Atualiza o stub com os dados completos
    const updatedData = {
      first_name,
      last_name,
      document,
      apartment: invite.apartment,
      contact_phone,
      email: invite.resident_email,
      role: "user",
      condominium_id: invite.condominium_id,
      registered: true,
    };

    await residentRepository.update(resident.id, updatedData);

    // 5) Opcional: busca novamente para retornar o objeto completo
    resident = await residentRepository.findById(resident.id);

    // 6) Marca o invite como usado
    await inviteRepository.markAsUsed(invite_code, resident.id);

    return resident;
  }
}

export default new InviteService();
