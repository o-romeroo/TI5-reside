import inviteService from './invite_service.js';
import inviteRepository from '../../infrastructure/repositories/invite_repository.js';
import residentRepository from '../../infrastructure/repositories/resident_repository.js';
import { v4 as uuidv4 } from 'uuid';
import nodemailer, { mockSendMail } from 'nodemailer';

jest.mock('../../infrastructure/repositories/invite_repository.js', () => ({
  findByInviteCode: jest.fn(),
  create: jest.fn(),
  findValidInvite: jest.fn(),
  markAsUsed: jest.fn(),
}));

jest.mock('../../infrastructure/repositories/resident_repository.js', () => ({
  findByGoogleId: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
  findById: jest.fn(),
}));

jest.mock('uuid', () => ({
  v4: jest.fn(),
}));

jest.mock('nodemailer');

describe('InviteService', () => {
  
  beforeEach(() => {
    jest.clearAllMocks();
  });


  describe('generateUniqueCode', () => {
    it('should generate a unique code on the first try', async () => {
      // Arrange
      const testUuid = '12345678-abcd-efgh-ijkl-mnopqrstuvwx';
      uuidv4.mockReturnValue(testUuid);
      inviteRepository.findByInviteCode.mockResolvedValue(null);

      // Act
      const code = await inviteService.generateUniqueCode();

      // Assert
      expect(uuidv4).toHaveBeenCalledTimes(1);
      expect(inviteRepository.findByInviteCode).toHaveBeenCalledWith('12345678');
      expect(code).toBe('12345678');
    });

    it('should retry generation if a code collision occurs', async () => {
      // Arrange
      const firstUuid = '11111111-abcd-efgh-ijkl-mnopqrstuvwx';
      const secondUuid = '22222222-abcd-efgh-ijkl-mnopqrstuvwx';
      uuidv4.mockReturnValueOnce(firstUuid).mockReturnValueOnce(secondUuid);
      
      inviteRepository.findByInviteCode
        .mockResolvedValueOnce({ id: 1, invite_code: '11111111' })
        .mockResolvedValueOnce(null);

      // Act
      const code = await inviteService.generateUniqueCode();

      // Assert
      expect(uuidv4).toHaveBeenCalledTimes(2);
      expect(inviteRepository.findByInviteCode).toHaveBeenCalledTimes(2);
      expect(inviteRepository.findByInviteCode).toHaveBeenCalledWith('11111111');
      expect(inviteRepository.findByInviteCode).toHaveBeenCalledWith('22222222');
      expect(code).toBe('22222222');
    });
  });

  describe('sendInviteEmails', () => {
    it('should generate a code, create an invite in the DB, and send an email for each recipient', async () => {
      // Arrange
      const emailList = ['test1@example.com', 'test2@example.com'];
      const inviteDetails = { apartment: '101', condominium_id: 1 };
      
      const mockGeneratedCode1 = 'code1234';
      const mockGeneratedCode2 = 'code5678';
      
      const generateUniqueCodeSpy = jest.spyOn(inviteService, 'generateUniqueCode')
        .mockResolvedValueOnce(mockGeneratedCode1)
        .mockResolvedValueOnce(mockGeneratedCode2);
      
      const sendEmailSpy = jest.spyOn(inviteService, 'sendEmail').mockResolvedValue();

      const createdInvite1 = { id: 1, resident_email: emailList[0], invite_code: mockGeneratedCode1 };
      const createdInvite2 = { id: 2, resident_email: emailList[1], invite_code: mockGeneratedCode2 };
      inviteRepository.create
        .mockResolvedValueOnce(createdInvite1)
        .mockResolvedValueOnce(createdInvite2);

      // Act
      const result = await inviteService.sendInviteEmails(emailList, inviteDetails);

      // Assert
      expect(generateUniqueCodeSpy).toHaveBeenCalledTimes(2);
      
      expect(inviteRepository.create).toHaveBeenCalledTimes(2);
      expect(inviteRepository.create).toHaveBeenCalledWith(expect.objectContaining({ resident_email: emailList[0] }));
      expect(inviteRepository.create).toHaveBeenCalledWith(expect.objectContaining({ resident_email: emailList[1] }));

      expect(sendEmailSpy).toHaveBeenCalledTimes(2);
      expect(sendEmailSpy).toHaveBeenCalledWith(emailList[0], mockGeneratedCode1);
      expect(sendEmailSpy).toHaveBeenCalledWith(emailList[1], mockGeneratedCode2);

      expect(result).toEqual([createdInvite1, createdInvite2]);

      generateUniqueCodeSpy.mockRestore();
      sendEmailSpy.mockRestore();
    });
  });

  describe('sendEmail', () => {
    it('should call nodemailer with the correct parameters', async () => {
      // Arrange
      const email = 'recipient@example.com';
      const code = 'ABCDE123';
      mockSendMail.mockResolvedValue({ messageId: 'test-id' });

      // Act
      await inviteService.sendEmail(email, code);

      // Assert
      expect(nodemailer.createTransport).toHaveBeenCalledTimes(1);
      expect(mockSendMail).toHaveBeenCalledTimes(1);
      expect(mockSendMail).toHaveBeenCalledWith(expect.objectContaining({
        to: email,
        html: expect.stringContaining(code),
      }));
    });
  });

  describe('bindResidentToCondo', () => {
    const inviteCode = 'valid123';
    const residentData = { first_name: 'John', last_name: 'Doe', document: '123456789', contact_phone: '5511999999999', google_id: 'google123' };
    const mockInvite = { id: 1, resident_email: 'john.doe@example.com', apartment: '202', condominium_id: 10 };
    const finalResident = { id: 1, ...residentData, email: mockInvite.resident_email, registered: true };

    it('should bind resident correctly when resident stub does not exist', async () => {
      // Arrange
      inviteRepository.findValidInvite.mockResolvedValue(mockInvite);
      residentRepository.findByGoogleId.mockResolvedValue(null);
      residentRepository.create.mockResolvedValue({ id: 1, google_id: residentData.google_id, registered: false });
      residentRepository.findById.mockResolvedValue(finalResident);

      // Act
      const result = await inviteService.bindResidentToCondo(inviteCode, residentData);

      // Assert
      expect(residentRepository.update).toHaveBeenCalledWith(1, expect.objectContaining({ registered: true }));
      expect(inviteRepository.markAsUsed).toHaveBeenCalledWith(inviteCode, 1);
      expect(result).toEqual(finalResident);
    });

    it('should bind resident correctly when resident stub already exists', async () => {
      // Arrange
      const existingStub = { id: 5, google_id: residentData.google_id, registered: false };
      inviteRepository.findValidInvite.mockResolvedValue(mockInvite);
      residentRepository.findByGoogleId.mockResolvedValue(existingStub);
      residentRepository.findById.mockResolvedValue({ ...finalResident, id: 5 });

      // Act
      await inviteService.bindResidentToCondo(inviteCode, residentData);

      // Assert
      expect(residentRepository.create).not.toHaveBeenCalled();
      expect(residentRepository.update).toHaveBeenCalledWith(existingStub.id, expect.any(Object));
    });

    it('should throw an error for an invalid or expired invite code', async () => {
      // Arrange
      inviteRepository.findValidInvite.mockResolvedValue(null);

      // Act & Assert
      await expect(inviteService.bindResidentToCondo(inviteCode, residentData)).rejects.toThrow('Código inválido ou expirado.');
    });
  });
});