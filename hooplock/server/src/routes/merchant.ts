import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { one, q, tx } from '../db.js';
import { merchantScope, requireRole, requireUser } from '../auth.js';
import { badRequest, conflict, notFound } from '../errors.js';
import { hashPassword } from '../security.js';
import { audit } from '../services/audit.js';
import { merchantSettingsSchema, settingsOf } from '../services/settings.js';
import { todayIST } from '../services/loans.js';
import { phoneSchema } from './auth.js';

const merchantFields = z.object({
  name: z.string().trim().min(2).max(80),
  ownerName: z.string().trim().max(80).default(''),
  phone: phoneSchema,
  city: z.string().trim().max(60).default(''),
  address: z.string().trim().max(300).default(''),
  callNumbers: z.array(phoneSchema).max(3).default([]),
  upiId: z.string().trim().max(60).regex(/^([\w.-]+@[\w.-]+)?$/, 'UPI id looks wrong').default(''),
});

export async function merchantRoutes(app: FastifyInstance) {
  app.get('/api/dashboard', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const today = todayIST();
    const c = await one<any>(
      `select count(*)::int as total,
         count(*) filter (where status = 'active' and last_seen_at > now() - interval '3 days')::int as active,
         count(*) filter (where status = 'active' and (last_seen_at is null or last_seen_at <= now() - interval '3 days'))::int as inactive,
         count(*) filter (where status = 'removed')::int as removed,
         count(*) filter (where status = 'pending')::int as pending,
         count(*) filter (where status = 'released')::int as released,
         count(*) filter (where status = 'active' and lock_state = 'locked')::int as locked,
         count(*) filter (where status = 'active' and lock_state in ('warning','restricted'))::int as restricted
       from devices where merchant_id = $1`, [mid]);
    const m = await one<any>('select name, android_keys as "androidKeys", ios_keys as "iosKeys" from merchants where id = $1', [mid]);
    if (!m) throw notFound('Shop not found');
    const money = await one<any>(
      `select coalesce(sum(i.amount - i.paid_amount) filter (where i.due_date < $2::date), 0) as "overdueAmount",
              count(distinct l.id) filter (where i.due_date < $2::date) ::int as "overdueLoans",
              coalesce(sum(i.amount - i.paid_amount) filter (where i.due_date between $2::date and $2::date + 7), 0) as "dueThisWeek"
       from instalments i join loans l on l.id = i.loan_id where l.merchant_id = $1 and l.status = 'open' and i.paid_at is null`, [mid, today]);
    const collected = await one<any>(
      `select coalesce(sum((a.data->>'applied')::numeric), 0) as today from audit_log a
       where a.merchant_id = $1 and a.action = 'payment.record' and a.created_at >= ($2::date)::timestamp - interval '5 hours 30 minutes'`, [mid, today]);
    return { shop: m.name, keys: { android: m.androidKeys, ios: m.iosKeys }, devices: c, money: { ...money, collectedToday: collected.today } };
  });

  app.get('/api/merchant', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const m = await one<any>(
      `select id, name, owner_name as "ownerName", phone, city, address, call_numbers as "callNumbers", upi_id as "upiId",
              android_keys as "androidKeys", ios_keys as "iosKeys", settings, active, created_at as "createdAt" from merchants where id = $1`, [mid]);
    if (!m) throw notFound();
    return { ...m, settings: settingsOf(m.settings) };
  });

  app.patch('/api/merchant', async (req) => {
    const u = await requireUser(req);
    requireRole(u, 'owner', 'super_admin');
    const mid = merchantScope(req, u);
    const b = merchantFields.partial().extend({ settings: merchantSettingsSchema.partial().optional() }).parse(req.body);
    const cur = await one<any>('select settings from merchants where id = $1', [mid]);
    if (!cur) throw notFound();
    const settings = b.settings ? merchantSettingsSchema.parse({ ...settingsOf(cur.settings), ...b.settings }) : undefined;
    await q(
      `update merchants set name = coalesce($2, name), owner_name = coalesce($3, owner_name), phone = coalesce($4, phone),
         city = coalesce($5, city), address = coalesce($6, address), call_numbers = coalesce($7, call_numbers),
         upi_id = coalesce($8, upi_id), settings = coalesce($9, settings) where id = $1`,
      [mid, b.name ?? null, b.ownerName ?? null, b.phone ?? null, b.city ?? null, b.address ?? null, b.callNumbers ?? null, b.upiId ?? null,
        settings ? JSON.stringify(settings) : null]);
    await audit({ merchantId: mid, userId: u.id, action: 'merchant.update', data: b });
    return { ok: true };
  });

  // ---- Staff ----
  app.get('/api/staff', async (req) => {
    const u = await requireUser(req);
    requireRole(u, 'owner', 'super_admin');
    const mid = merchantScope(req, u);
    return { items: await q('select id, name, phone, role, active, created_at as "createdAt" from users where merchant_id = $1 order by created_at', [mid]) };
  });

  app.post('/api/staff', async (req) => {
    const u = await requireUser(req);
    requireRole(u, 'owner', 'super_admin');
    const mid = merchantScope(req, u);
    const b = z.object({ name: z.string().trim().min(2).max(80), phone: phoneSchema, password: z.string().min(8), role: z.enum(['owner', 'staff']).default('staff') }).parse(req.body);
    if (await one('select 1 from users where phone = $1', [b.phone])) throw conflict('This mobile number already has an account');
    const r = await one<{ id: string }>('insert into users(merchant_id, role, name, phone, password_hash) values ($1,$2,$3,$4,$5) returning id',
      [mid, b.role, b.name, b.phone, await hashPassword(b.password)]);
    await audit({ merchantId: mid, userId: u.id, action: 'staff.create', target: r!.id, data: { name: b.name, role: b.role } });
    return r;
  });

  app.patch('/api/staff/:id', async (req) => {
    const u = await requireUser(req);
    requireRole(u, 'owner', 'super_admin');
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    if (id === u.id) throw badRequest('You cannot change your own account here');
    const b = z.object({ active: z.boolean().optional(), password: z.string().min(8).optional() }).parse(req.body);
    const r = await q('update users set active = coalesce($3, active), password_hash = coalesce($4, password_hash) where id = $1 and merchant_id = $2 returning id',
      [id, mid, b.active ?? null, b.password ? await hashPassword(b.password) : null]);
    if (!r.length) throw notFound();
    await audit({ merchantId: mid, userId: u.id, action: 'staff.update', target: id, data: { active: b.active, passwordReset: !!b.password } });
    return { ok: true };
  });

  // ---- Keys ----
  app.get('/api/keys/ledger', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    return {
      items: await q(
        `select k.id, k.platform, k.delta, k.reason, k.device_id as "deviceId", k.created_at as "at", c.name as customer
         from key_ledger k left join devices d on d.id = k.device_id left join customers c on c.id = d.customer_id
         where k.merchant_id = $1 order by k.created_at desc limit 200`, [mid]),
    };
  });

  // ---- Audit and reports ----
  app.get('/api/audit', async (req) => {
    const u = await requireUser(req);
    requireRole(u, 'owner', 'super_admin');
    const mid = merchantScope(req, u);
    return {
      items: await q(
        `select a.id, a.action, a.target, a.data, a.created_at as "at", u.name as "by" from audit_log a left join users u on u.id = a.user_id
         where a.merchant_id = $1 order by a.created_at desc limit 300`, [mid]),
    };
  });

  app.get('/api/reports/summary', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const p = z.object({ from: z.string().regex(/^\d{4}-\d{2}-\d{2}$/), to: z.string().regex(/^\d{4}-\d{2}-\d{2}$/) }).parse(req.query);
    const r = await one<any>(
      `select
         (select count(*)::int from devices where merchant_id = $1 and enrolled_at::date between $2 and $3) as enrolled,
         (select count(*)::int from loans where merchant_id = $1 and created_at::date between $2 and $3) as sales,
         (select coalesce(sum(total_amount - down_payment),0) from loans where merchant_id = $1 and created_at::date between $2 and $3) as financed,
         (select coalesce(sum((data->>'applied')::numeric),0) from audit_log where merchant_id = $1 and action = 'payment.record' and created_at::date between $2 and $3) as collected,
         (select count(*)::int from audit_log where merchant_id = $1 and action = 'device.locked' and created_at::date between $2 and $3) as locks,
         (select count(*)::int from audit_log where merchant_id = $1 and action = 'device.unlocked' and created_at::date between $2 and $3) as unlocks,
         (select count(*)::int from devices where merchant_id = $1 and released_at::date between $2 and $3) as released`,
      [mid, p.from, p.to]);
    return r;
  });

  app.get('/api/reports/devices.csv', async (req, reply) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const rows = await q<any>(
      `select c.name, c.mobile, d.platform, d.brand, d.model, d.imei1, d.imei2, d.serial, d.status, d.lock_state, d.last_seen_at,
              l.total_amount, l.down_payment, l.emi_amount, l.emi_count, l.status as loan_status,
              (select coalesce(sum(amount - paid_amount),0) from instalments i where i.loan_id = l.id and i.paid_at is null) as balance
       from devices d join customers c on c.id = d.customer_id left join loans l on l.device_id = d.id
       where d.merchant_id = $1 order by d.created_at desc`, [mid]);
    const cols = Object.keys(rows[0] ?? { name: '' });
    const esc = (v: unknown) => { const s = v == null ? '' : v instanceof Date ? v.toISOString() : String(v); return /[",\n]/.test(s) || /^[=+\-@]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s; };
    reply.header('content-disposition', 'attachment; filename="hooplock-devices.csv"').type('text/csv');
    return [cols.join(','), ...rows.map((r) => cols.map((c) => esc(r[c])).join(','))].join('\n');
  });

  // ---- Super admin: shops and keys ----
  app.get('/api/admin/merchants', async (req) => {
    const u = await requireUser(req);
    requireRole(u, 'super_admin');
    return {
      items: await q(
        `select m.id, m.name, m.owner_name as "ownerName", m.phone, m.city, m.android_keys as "androidKeys", m.ios_keys as "iosKeys", m.active,
                (select count(*)::int from devices d where d.merchant_id = m.id) as devices,
                (select count(*)::int from devices d where d.merchant_id = m.id and d.status = 'active') as "activeDevices"
         from merchants m order by m.created_at desc`),
    };
  });

  app.post('/api/admin/merchants', async (req) => {
    const u = await requireUser(req);
    requireRole(u, 'super_admin');
    const b = merchantFields.extend({ ownerPassword: z.string().min(8), androidKeys: z.number().int().min(0).default(0), iosKeys: z.number().int().min(0).default(0) }).parse(req.body);
    if (await one('select 1 from users where phone = $1', [b.phone])) throw conflict('This mobile number already has an account');
    const id = await tx(async (c) => {
      const m = await one<{ id: string }>(
        `insert into merchants(name, owner_name, phone, city, address, call_numbers, upi_id, android_keys, ios_keys)
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9) returning id`,
        [b.name, b.ownerName, b.phone, b.city, b.address, b.callNumbers, b.upiId, b.androidKeys, b.iosKeys], c);
      await q("insert into users(merchant_id, role, name, phone, password_hash) values ($1,'owner',$2,$3,$4)",
        [m!.id, b.ownerName || b.name, b.phone, await hashPassword(b.ownerPassword)], c);
      for (const [platform, n] of [['android', b.androidKeys], ['ios', b.iosKeys]] as const) {
        if (n > 0) await q("insert into key_ledger(merchant_id, platform, delta, reason, created_by) values ($1,$2,$3,'opening',$4)", [m!.id, platform, n, u.id], c);
      }
      await audit({ merchantId: m!.id, userId: u.id, action: 'merchant.create', data: { name: b.name } }, c);
      return m!.id;
    });
    return { id };
  });

  app.patch('/api/admin/merchants/:id', async (req) => {
    const u = await requireUser(req);
    requireRole(u, 'super_admin');
    const { id } = req.params as { id: string };
    const b = z.object({ active: z.boolean() }).parse(req.body);
    await q('update merchants set active = $2 where id = $1', [id, b.active]);
    await audit({ merchantId: id, userId: u.id, action: b.active ? 'merchant.enable' : 'merchant.disable' });
    return { ok: true };
  });

  app.post('/api/admin/merchants/:id/keys', async (req) => {
    const u = await requireUser(req);
    requireRole(u, 'super_admin');
    const { id } = req.params as { id: string };
    const b = z.object({ platform: z.enum(['android', 'ios']), count: z.number().int().min(-10000).max(10000).refine((n) => n !== 0), reason: z.string().trim().min(2).max(120) }).parse(req.body);
    const col = b.platform === 'android' ? 'android_keys' : 'ios_keys';
    const r = await tx(async (c) => {
      const m = await one<any>(`update merchants set ${col} = ${col} + $2 where id = $1 and ${col} + $2 >= 0 returning ${col} as balance`, [id, b.count], c);
      if (!m) throw badRequest('Shop not found or balance would go below zero');
      await q('insert into key_ledger(merchant_id, platform, delta, reason, created_by) values ($1,$2,$3,$4,$5)', [id, b.platform, b.count, b.reason, u.id], c);
      await audit({ merchantId: id, userId: u.id, action: 'keys.adjust', data: b }, c);
      return m;
    });
    return { balance: r.balance };
  });
}
