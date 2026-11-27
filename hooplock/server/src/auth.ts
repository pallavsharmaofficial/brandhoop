import { SignJWT, jwtVerify } from 'jose';
import type { FastifyRequest } from 'fastify';
import { config } from './config.js';
import { one } from './db.js';
import { forbidden, unauthorized, badRequest } from './errors.js';
import { sha256, safeEqual } from './security.js';

export type Role = 'super_admin' | 'owner' | 'staff';
export interface AuthUser { id: string; role: Role; merchantId: string | null; name: string }

const key = new TextEncoder().encode(config.jwtSecret);

export async function issueToken(u: AuthUser): Promise<string> {
  return new SignJWT({ role: u.role, mid: u.merchantId, name: u.name })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(u.id)
    .setIssuedAt()
    .setExpirationTime('12h')
    .sign(key);
}

declare module 'fastify' {
  interface FastifyRequest { user?: AuthUser; device?: { id: string; merchantId: string } }
}

export async function requireUser(req: FastifyRequest): Promise<AuthUser> {
  let h = req.headers.authorization ?? '';
  // File downloads opened in a browser tab (CSV export) cannot set headers.
  const qt = (req.query as any)?.access_token;
  if (!h && req.method === 'GET' && typeof qt === 'string' && req.url.startsWith('/api/reports/')) h = `Bearer ${qt}`;
  if (!h.startsWith('Bearer ')) throw unauthorized();
  try {
    const { payload } = await jwtVerify(h.slice(7), key, { algorithms: ['HS256'] });
    const row = await one<{ active: boolean; m_active: boolean | null }>(
      'select u.active, m.active as m_active from users u left join merchants m on m.id = u.merchant_id where u.id = $1',
      [payload.sub],
    );
    if (!row || !row.active || row.m_active === false) throw unauthorized('Account disabled');
    const u: AuthUser = { id: payload.sub!, role: payload.role as Role, merchantId: (payload.mid as string) ?? null, name: String(payload.name ?? '') };
    req.user = u;
    return u;
  } catch (e) {
    if ((e as any).statusCode) throw e;
    throw unauthorized();
  }
}

export function requireRole(u: AuthUser, ...roles: Role[]) {
  if (!roles.includes(u.role)) throw forbidden();
}

/** Merchant the request acts on. Super admin can act for any merchant with ?merchantId=. */
export function merchantScope(req: FastifyRequest, u: AuthUser): string {
  if (u.role === 'super_admin') {
    const m = (req.query as any)?.merchantId ?? (req.headers['x-merchant-id'] as string | undefined);
    if (!m) throw badRequest('Choose a shop first (merchantId)');
    return String(m);
  }
  return u.merchantId!;
}

/** Agent (phone) auth: "Authorization: Device <deviceId>.<apiToken>" */
export async function requireDevice(req: FastifyRequest) {
  const h = req.headers.authorization ?? '';
  const m = /^Device ([0-9a-f-]{36})\.(.+)$/.exec(h);
  if (!m) throw unauthorized('Device not registered');
  const row = await one<{ id: string; merchant_id: string; api_token_hash: string | null }>(
    'select id, merchant_id, api_token_hash from devices where id = $1', [m[1]],
  );
  if (!row?.api_token_hash || !safeEqual(row.api_token_hash, sha256(m[2]))) throw unauthorized('Device not registered');
  req.device = { id: row.id, merchantId: row.merchant_id };
  return req.device;
}
