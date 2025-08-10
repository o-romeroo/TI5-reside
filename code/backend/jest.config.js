/** @type {import('jest').Config} */
const config = {
  clearMocks: true,

  moduleFileExtensions: ['js'],

  testEnvironment: 'node',

  testMatch: [
    '**/__tests__/**/*.js?(x)',
    '**/?(*.)+(spec|test).js?(x)',
  ],

  testPathIgnorePatterns: ['/node_modules/'],
  transform: {
    '^.+\\.js$': 'babel-jest',
  },
  transformIgnorePatterns: ['/node_modules/'],
};

export default config;