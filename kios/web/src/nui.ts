declare global {
  interface Window {
    GetParentResourceName?: () => string;
  }
}

export const isBrowser = typeof window.GetParentResourceName !== 'function';

const resource = isBrowser ? 'kios' : window.GetParentResourceName!();

export async function post<T = unknown>(event: string, data: unknown = {}): Promise<T | undefined> {
  if (isBrowser) return undefined;
  try {
    const res = await fetch(`https://${resource}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    return (await res.json()) as T;
  } catch {
    return undefined;
  }
}
