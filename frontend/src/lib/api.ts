// frontend/src/lib/api.ts
// API configuration helper

const API_URL =
  import.meta.env.VITE_API_URL || (import.meta.env.DEV ? 'http://localhost:3001' : '/api');

export const getApiUrl = (endpoint: string): string => {
  // Normalize both pieces so we never generate /api/api/... by accident.
  const base = API_URL.replace(/\/+$/, '');
  let cleanEndpoint = endpoint.replace(/^\/+/, '');

  if (base.endsWith('/api') && cleanEndpoint.startsWith('api/')) {
    cleanEndpoint = cleanEndpoint.slice(4);
  }

  return `${base}/${cleanEndpoint}`;
};

export default API_URL;

