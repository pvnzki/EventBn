// Small helper to centralize API base URL for client code
export const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

export function apiUrl(path: string) {
  // Ensure we don't accidentally duplicate slashes
  return `${API_BASE.replace(/\/+$/, '')}/${path.replace(/^\/+/, '')}`;
}
