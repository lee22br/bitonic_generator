import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export const options = {
  stages: [
    { duration: '30s', target: 5 },   // Ramp up to 5 users
    { duration: '2m', target: 10 },   // Stay at 10 users  
    { duration: '1m', target: 20 },   // Increase to 20 users
    { duration: '30s', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'], // 95% of requests under 1s
    http_req_failed: ['rate<0.1'],     // Less than 10% failures
  },
};

// Simple test data based on Bruno spec
const testCases = [
  { length: 7, start: 2, end: 5 },   // Original Bruno example
  { length: 5, start: 1, end: 5 },   
  { length: 10, start: 0, end: 10 }, 
  { length: 3, start: 2, end: 4 },
  { length: 4, start: 4, end: 1 },
  { length: 5, start: 1, end: 6 },
  { length: 29, start: 1, end: 15 }
];

export default function () {
  // Pick random test case
  const testData = testCases[Math.floor(Math.random() * testCases.length)];
  
  const payload = JSON.stringify(testData);

  const response = http.post(`${BASE_URL}/bitonic`, payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  // Basic validation
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time OK': (r) => r.timings.duration < 1000,
    'has sequence': (r) => {
      try {
        const json = JSON.parse(r.body);
        return json.hasOwnProperty('sequence');
      } catch {
        return false;
      }
    },
  });

  sleep(1); // 1 second between requests
}