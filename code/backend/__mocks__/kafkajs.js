export const mockProducerSend = jest.fn();
export const mockProducerConnect = jest.fn();
export const mockProducerDisconnect = jest.fn();
export const mockConsumer = jest.fn();

const mockProducer = {
  connect: mockProducerConnect,
  send: mockProducerSend,
  disconnect: mockProducerDisconnect,
};

export const Kafka = jest.fn().mockImplementation(() => ({
  producer: () => mockProducer,
  consumer: mockConsumer,
}));