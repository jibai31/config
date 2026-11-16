const BASE_URL = 'https://api.example.test';

export async function apiFetch(path: string): Promise<any> {
  const response = await fetch(`${BASE_URL}${path}`);
  if (!response.ok) throw new Error(`API ${path} failed: ${response.status}`);
  return response.json();
}
