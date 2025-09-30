// k6 Configuration File
// This file contains common configuration options for k6 tests

// Export default configuration
export const defaultOptions = {
  // Global thresholds that apply to all tests
  thresholds: {
    http_req_duration: ['p(95)<1000'],   // 95% of requests should be under 1s
    http_req_failed: ['rate<0.1'],       // Error rate should be less than 10%
  },
  
  // Default scenarios can be overridden in individual test files
  scenarios: {
    default: {
      executor: 'constant-vus',
      vus: 1,
      duration: '30s',
    },
  },
};

// Environment-specific configurations
export const environments = {
  local: {
    baseUrl: 'http://localhost:8080',
    timeout: '30s',
  },
  
  staging: {
    baseUrl: 'https://staging-api.example.com',
    timeout: '60s',
  },
  
  production: {
    baseUrl: 'https://api.example.com',
    timeout: '60s',
  },
};

// Test-specific configurations
export const testConfigs = {
  smoke: {
    vus: 1,
    duration: '1m',
    thresholds: {
      http_req_duration: ['p(95)<500'],
      http_req_failed: ['rate<0.01'],
    },
  },
  
  load: {
    stages: [
      { duration: '1m', target: 10 },
      { duration: '3m', target: 10 },
      { duration: '1m', target: 0 },
    ],
    thresholds: {
      http_req_duration: ['p(95)<1000'],
      http_req_failed: ['rate<0.05'],
    },
  },
  
  stress: {
    stages: [
      { duration: '30s', target: 50 },
      { duration: '1m', target: 100 },
      { duration: '30s', target: 0 },
    ],
    thresholds: {
      http_req_duration: ['p(95)<2000'],
      http_req_failed: ['rate<0.2'],
    },
  },
  
  spike: {
    stages: [
      { duration: '10s', target: 200 },
      { duration: '30s', target: 200 },
      { duration: '10s', target: 0 },
    ],
    thresholds: {
      http_req_duration: ['p(95)<3000'],
      http_req_failed: ['rate<0.3'],
    },
  },
};