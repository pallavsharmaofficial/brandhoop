import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { one, q, tx } from '../db.js';
import { merchantScope, requireUser } from '../auth.js';
import { badRequest, notFound } from '../errors.js';
import { audit } from '../services/audit.js';
import { createInstalments, loanSummary, todayIST, buildSchedule } from '../services/loans.js';
import { issueEnrollment } from '../services/devices.js';
import { phoneSchema } from './auth.js';

const LIST_SQL = `
select c.id as "customerId", c.name, c.mobile, (c.photo is not null) as "hasPhoto",
       d.id as "deviceId", d.platform, d.status, d.lock_state as "lockState", d.reported_state as "reportedState",
       d.brand, d.model, d.imei1, d.imei2, d.serial, d.sim1_number as "sim1Number",
       d.last_seen_at as "lastSeenAt", d.created_at as "createdAt",
       l.status as "loanStatus", l.emi_amount as "emiAmount",
       n.due_date as "nextDueDate", n.amount as "nextDueAmount",
       o.amount as "overdueAmount", o.oldest as "oldestOverdue"
from devices d
join customers c on c.id = d.customer_id
left join loans l on l.device_id = d.id
left join lateral (select i.due_date, i.amount - i.paid_amount as amount from instalments i
                   where i.loan_id = l.id and i.paid_at is null order by i.seq limit 1) n on true
left join lateral (select coalesce(sum(i.amount - i.paid_amount), 0) as amount, min(i.due_date) as oldest from instalments i
                   where i.loan_id = l.id and i.paid_at is null and i.due_date < $2::date) o on true
where d.merchant_id = $1`;

const saleSchema = z.object({
  platform: z.enum(['android', 'ios']),
  customer: z.object({
    name: z.string().trim().min(2).max(80),
    mobile: phoneSchema,
    altMobile: z.union([phoneSchema, z.literal('')]).default(''),
    address: z.string().trim().max(300).default(''),
    idType: z.string().trim().max(30).default(''),
    idLast4: z.string().trim().max(4).default(''),
    notes: z.string().trim().max(500).default(''),
  }),
  device: z.object({
    brand: z.string().trim().max(40).default(''),
    model: z.string().trim().max(60).default(''),
    imei1: z.string().trim().regex(/^(\d{15})?$/, 'IMEI is 15 digits').default(''),
    imei2: z.string().trim().regex(/^(\d{15})?$/, 'IMEI is 15 digits').default(''),
    serial: z.string().trim().max(40).default(''),
  }).default({}),
  loan: z.object({
    totalAmount: z.number().positive().max(1_000_000),
    downPayment: z.number().min(0).max(1_000_000).default(0),
    emiAmount: z.number().positive().max(1_000_000),
    emiCount: z.number().int().min(1).max(60),
    firstEmiDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    loanRef: z.string().trim().max(60).default(''),
    notes: z.string().trim().max(500).default(''),
  }),
});

export async function customerRoutes(app: FastifyInstance) {
  app.get('/api/customers', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const p = z.object({
      tab: z.enum(['users', 'next_emi', 'high_risk']).default('users'),
      q: z.string().trim().max(60).default(''),
      status: z.enum(['all', 'pending', 'active', 'inactive', 'removed', 'released', 'locked']).default('all'),
      platform: z.enum(['all', 'android', 'ios']).default('all'),
      limit: z.coerce.number().int().min(1).max(100).default(30),
      offset: z.coerce.number().int().min(0).default(0),
    }).parse(req.query);
    const today = todayIST();
    const params: unknown[] = [mid, today];
    let sql = LIST_SQL;
    if (p.q) {
      params.push(`%${p.q}%`);
      sql += ` and (c.name ilike $${params.length} or c.mobile like $${params.length} or d.imei1 like $${params.length} or d.imei2 like $${params.length} or d.serial ilike $${params.length})`;
    }
    if (p.platform !== 'all') { params.push(p.platform); sql += ` and d.platform = $${params.length}`; }
    const statusFilter: Record<string, string> = {
      pending: "d.status = 'pending'",
      active: "d.status = 'active' and d.last_seen_at > now() - interval '3 days'",
      inactive: "d.status = 'active' and (d.last_seen_at is null or d.last_seen_at <= now() - interval '3 days')",
      removed: "d.status = 'removed'",
      released: "d.status = 'released'",
      locked: "d.status = 'active' and d.lock_state = 'locked'",
    };
    if (p.status !== 'all') sql += ` and ${statusFilter[p.status]}`;
    if (p.tab === 'next_emi') {
      sql += ` and l.status = 'open' and n.due_date <= ($2::date + 7) order by n.due_date asc, c.name`;
    } else if (p.tab === 'high_risk') {
      sql += ` and d.status in ('active','pending') and (o.oldest is not null or d.lock_state <> 'unlocked'
               or (d.status = 'active' and d.last_seen_at <= now() - interval '3 days')
               or exists (select 1 from device_events e where e.device_id = d.id and e.type in ('sim_changed','tamper') and e.created_at > now() - interval '7 days'))
               order by o.oldest asc nulls last, d.last_seen_at asc nulls first`;
    } else {
      sql += ' order by d.created_at desc';
    }
    params.push(p.limit, p.offset);
    sql += ` limit $${params.length - 1} offset $${params.length}`;
    const rows = await q<any>(sql, params);
    return {
      items: rows.map((r) => ({
        ...r,
        overdueDays: r.oldestOverdue ? Math.round((Date.parse(today) - Date.parse(r.oldestOverdue)) / 86400000) : 0,
      })),
    };
  });

  /** New credit sale: customer + phone + loan + EMI schedule, and (Android) a QR to enroll it. */
  app.post('/api/sales', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const b = saleSchema.parse(req.body);
    const financed = b.loan.totalAmount - b.loan.downPayment;
    if (financed <= 0) throw badRequest('Down payment must be less than the total price');
    if (b.loan.emiAmount * b.loan.emiCount < financed * 0.95) throw badRequest('EMIs do not cover the financed amount');
    if (b.platform === 'ios' && !b.device.serial) throw badRequest('Enter the iPhone serial number');

    const m = await one<{ android_keys: number; ios_keys: number }>('select android_keys, ios_keys from merchants where id = $1', [mid]);
    if (!m) throw notFound('Shop not found');
    if ((b.platform === 'android' ? m.android_keys : m.ios_keys) <= 0) throw badRequest(`No ${b.platform === 'android' ? 'Android' : 'iPhone'} keys left. Ask the admin to add keys.`);

    const ids = await tx(async (c) => {
      const cu = await one<{ id: string }>(
        `insert into customers(merchant_id, name, mobile, alt_mobile, address, id_type, id_last4, notes)
         values ($1,$2,$3,$4,$5,$6,$7,$8) returning id`,
        [mid, b.customer.name, b.customer.mobile, b.customer.altMobile, b.customer.address, b.customer.idType, b.customer.idLast4, b.customer.notes], c);
      const dv = await one<{ id: string }>(
        `insert into devices(merchant_id, customer_id, platform, brand, model, imei1, imei2, serial, sim1_number)
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9) returning id`,
        [mid, cu!.id, b.platform, b.device.brand, b.device.model, b.device.imei1, b.device.imei2, b.device.serial, b.customer.mobile], c);
      const ln = await one<{ id: string }>(
        `insert into loans(device_id, merchant_id, total_amount, down_payment, emi_amount, emi_count, first_emi_date, loan_ref, notes)
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9) returning id`,
        [dv!.id, mid, b.loan.totalAmount, b.loan.downPayment, b.loan.emiAmount, b.loan.emiCount, b.loan.firstEmiDate, b.loan.loanRef, b.loan.notes], c);
      await createInstalments(ln!.id, b.loan.firstEmiDate, b.loan.emiCount, b.loan.emiAmount, c);
      await audit({ merchantId: mid, userId: u.id, action: 'sale.create', target: dv!.id, data: { platform: b.platform, total: b.loan.totalAmount } }, c);
      return { customerId: cu!.id, deviceId: dv!.id, loanId: ln!.id };
    });
    const enrollment = b.platform === 'android' ? await issueEnrollment(ids.deviceId, mid) : null;
    return { ...ids, enrollment };
  });

  app.post('/api/sales/preview', async (req) => {
    await requireUser(req);
    const b = z.object({ firstEmiDate: z.string(), emiCount: z.number().int().min(1).max(60), emiAmount: z.number().positive() }).parse(req.body);
    return { schedule: buildSchedule(b.firstEmiDate, b.emiCount, b.emiAmount) };
  });

  app.get('/api/devices/:id', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const d = await one<any>(
      `select d.id, d.platform, d.status, d.lock_state as "lockState", d.lock_reason as "lockReason", d.lock_message as "lockMessage",
              d.reported_state as "reportedState", d.state_seq as "stateSeq", d.imei1, d.imei2, d.serial, d.brand, d.model,
              d.os_version as "osVersion", d.agent_version as "agentVersion", d.sim1_number as "sim1Number", d.sim1_operator as "sim1Operator",
              d.sim2_number as "sim2Number", d.sim2_operator as "sim2Operator", d.battery, d.last_seen_at as "lastSeenAt",
              d.enrolled_at as "enrolledAt", d.released_at as "releasedAt", d.created_at as "createdAt", (d.fcm_token is not null) as "push",
              json_build_object('id', c.id, 'name', c.name, 'mobile', c.mobile, 'altMobile', c.alt_mobile, 'address', c.address,
                 'idType', c.id_type, 'idLast4', c.id_last4, 'notes', c.notes, 'hasPhoto', c.photo is not null) as customer,
              json_build_object('id', l.id, 'totalAmount', l.total_amount, 'downPayment', l.down_payment, 'emiAmount', l.emi_amount,
                 'emiCount', l.emi_count, 'firstEmiDate', l.first_emi_date, 'loanRef', l.loan_ref, 'notes', l.notes,
                 'status', l.status, 'consentAt', l.consent_at) as loan
       from devices d join customers c on c.id = d.customer_id left join loans l on l.device_id = d.id
       where d.id = $1 and d.merchant_id = $2`, [id, mid]);
    if (!d) throw notFound('Device not found');
    const instalments = await q<any>(
      `select id, seq, due_date as "dueDate", amount, paid_amount as "paidAmount", paid_at as "paidAt", method, ref
       from instalments where loan_id = $1 order by seq`, [d.loan.id]);
    const lastLocation = await one<any>('select lat, lng, accuracy, reason, created_at as "at" from locations where device_id = $1 order by created_at desc limit 1', [id]);
    return { ...d, instalments, summary: await loanSummary(id), lastLocation: lastLocation ?? null };
  });

  app.patch('/api/customers/:id', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const b = saleSchema.shape.customer.partial().parse(req.body);
    const cols: Record<string, unknown> = { name: b.name, mobile: b.mobile, alt_mobile: b.altMobile, address: b.address, id_type: b.idType, id_last4: b.idLast4, notes: b.notes };
    const sets: string[] = []; const vals: unknown[] = [id, mid];
    for (const [k, v] of Object.entries(cols)) if (v !== undefined) { vals.push(v); sets.push(`${k} = $${vals.length}`); }
    if (!sets.length) return { ok: true };
    const r = await q(`update customers set ${sets.join(', ')} where id = $1 and merchant_id = $2 returning id`, vals);
    if (!r.length) throw notFound();
    await audit({ merchantId: mid, userId: u.id, action: 'customer.update', target: id, data: b });
    return { ok: true };
  });

  app.put('/api/customers/:id/photo', { bodyLimit: 3 * 1024 * 1024 }, async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const b = z.object({ dataBase64: z.string().max(2_800_000), type: z.enum(['image/jpeg', 'image/png', 'image/webp']) }).parse(req.body);
    const r = await q('update customers set photo = $3, photo_type = $4 where id = $1 and merchant_id = $2 returning id',
      [id, mid, Buffer.from(b.dataBase64, 'base64'), b.type]);
    if (!r.length) throw notFound();
    return { ok: true };
  });

  app.get('/api/customers/:id/photo', async (req, reply) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const r = await one<{ photo: Buffer | null; photo_type: string }>('select photo, photo_type from customers where id = $1 and merchant_id = $2', [id, mid]);
    if (!r?.photo) throw notFound();
    reply.header('cache-control', 'private, max-age=3600').type(r.photo_type);
    return r.photo;
  });
}
