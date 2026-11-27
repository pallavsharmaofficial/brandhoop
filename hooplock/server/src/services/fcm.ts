import { importPKCS8, SignJWT } from 'jose';
import { config } from '../config.js';

/**
 * Firebase Cloud Messaging (HTTP v1). The push only says "sync now"; the phone then fetches its
 * signed state over HTTPS, so nothing sensitive travels through Google.
 * Without FCM_SERVICE_ACCOUNT, phones still sync on their own every 15 minutes.
 */
let cached: { token: string; exp: number } | null = null;

async function accessToken(): Promise<string | null> {
  if (!config.fcmServiceAccount) return null;
  if (cached && cached.exp > Date.now() + 60_000) return cached.token;
  const sa = JSON.parse(config.fcmServiceAccount);
  const key = await importPKCS8(sa.private_key, 'RS256');
  const assertion = await new SignJWT({ scope: 'https://www.googleapis.com/auth/firebase.messaging' })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(key);
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
  });
  if (!r.ok) throw new Error(`FCM auth failed: ${r.status}`);
  const j = (await r.json()) as { access_token: string; expires_in: number };
  cached = { token: j.access_token, exp: Date.now() + j.expires_in * 1000 };
  return cached.token;
}

export async function pushSync(fcmToken: string | null | undefined, log?: { warn: (o: unknown, m: string) => void }): Promise<boolean> {
  if (!fcmToken) return false;
  try {
    const token = await accessToken();
    if (!token) return false;
    const projectId = JSON.parse(config.fcmServiceAccount).project_id;
    const r = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
      body: JSON.stringify({ message: { token: fcmToken, data: { t: 'sync' }, android: { priority: 'HIGH', ttl: '86400s' } } }),
    });
    if (!r.ok) log?.warn({ status: r.status, body: await r.text() }, 'FCM send failed');
    return r.ok;
  } catch (e) {
    log?.warn({ err: (e as Error).message }, 'FCM send error');
    return false;
  }
}
