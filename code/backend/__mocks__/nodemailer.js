export const mockSendMail = jest.fn();

export default {
  createTransport: jest.fn().mockReturnValue({
    sendMail: mockSendMail,
  }),
};