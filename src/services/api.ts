const BASE_URL = 'http://localhost:8000'; // Adjust for production

export async function uploadTasks(tasks: any[]) {
    const res = await fetch(`${BASE_URL}/tasks/upload`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            // Add 'Authorization': `Bearer ${token}` if auth is implemented
        },
        body: JSON.stringify({ tasks }),
    });

    if (!res.ok) throw new Error('Failed to upload tasks');
    return await res.json();
}

export async function fetchUserTier(): Promise<'free' | 'plus' | 'pro'> {
    const res = await fetch(`${BASE_URL}/users/tier`, {
        headers: {
            'Content-Type': 'application/json',
        },
    });

    if (!res.ok) throw new Error('Failed to fetch user tier');
    const data = await res.json();
    return data.tier;
}

export const getUserSession = async () => {
  const res = await fetch('/api/session');
  if (!res.ok) throw new Error('Failed to fetch session');
  return res.json();
};
