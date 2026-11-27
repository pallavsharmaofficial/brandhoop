import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { one, q } from '../db.js';
import { issueToken, requireUser } from '../auth.js';
import { badRequest, unauthorized } from '../errors.js';
import { hashPassword, verifyPassword } from '../security.js';
import { audit } from '../services/audit.js';

export const phoneSchema = z.string().trim().regex(/^[6-9]\d{9}$/, 'Enter a 10-digit mobile number');

export async function authRoutes(app: FastifyInstance) {
  app.post('/api/auth/login', { config: { rateLimit: { max: 10, timeWindow: '1 minute' } } }, async (req) => {
    const body = z.object({ phone: phoneSchema, password: z.string().min(1) }).parse(req.body);
    const u = await one<any>(
      `select u.*, m.name as merchant_name, m.active as m_active from users u left join merchants m on m.id = u.merchant_id where u.phone = $1`,
      [body.phone]);
    if (!u || !(await verifyPassword(body.password, u.password_hash))) throw unauthorized('Wrong mobile number or password');
    if (!u.active || u.m_active === false) throw unauthorized('This account is disabled');
    const user = { id: u.id, role: u.role, merchantId: u.merchant_id, name: u.name };
    await audit({ merchantId: u.merchant_id, userId: u.id, action: 'auth.login' });
    return { token: await issueToken(user), user: { ...user, phone: u.phone, merchantName: u.merchant_name } };
  });

  app.get('/api/me', async (req) => {
    const u = await requireUser(req);
    const row = await one<any>(
      `select u.id, u.name, u.phone, u.role, u.merchant_id as "merchantId", m.name as "merchantName"
       from users u left join merchants m on m.id = u.merchant_id where u.id = $1`, [u.id]);
    return row;
  });

  app.patch('/api/me', async (req) => {
    const u = await requireUser(req);
    const body = z.object({ name: z.string().trim().min(2).max(80).optional(), phone: phoneSchema.optional() }).parse(req.body);
    if (body.phone && (await one('select 1 from users where phone = $1 and id <> $2', [body.phone, u.id]))) throw badRequest('This mobile number already has an account');
    await q('update users set name = coalesce($2, name), phone = coalesce($3, phone) where id = $1', [u.id, body.name ?? null, body.phone ?? null]);
    await audit({ merchantId: u.merchantId, userId: u.id, action: 'auth.profile_changed', data: body });
    return { ok: true };
  });

  app.post('/api/me/password', async (req) => {
    const u = await requireUser(req);
    const body = z.object({ current: z.string(), next: z.string().min(8, 'Use at least 8 characters') }).parse(req.body);
    const row = await one<{ password_hash: string }>('select password_hash from users where id = $1', [u.id]);
    if (!(await verifyPassword(body.current, row!.password_hash))) throw badRequest('Current password is wrong');
    await q('update users set password_hash = $2 where id = $1', [u.id, await hashPassword(body.next)]);
    await audit({ merchantId: u.merchantId, userId: u.id, action: 'auth.password_changed' });
    return { ok: true };
  });
}
