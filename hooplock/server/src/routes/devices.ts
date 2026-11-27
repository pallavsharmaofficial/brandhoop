import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { one, q, tx } from '../db.js';
import { merchantScope, requireUser, requireRole } from '../auth.js';
import { badRequest, conflict } from '../errors.js';
import { audit } from '../services/audit.js';
import { applyPayment, loanSummary } from '../services/loans.js';
import { getDevice, issueEnrollment, LOCK_REASONS, requestRelease, setLockState } from '../services/devices.js';
import { pushSync } from '../services/fcm.js';
import { sendSms } from '../services/sms.js';
import { smsCommand } from '../security.js';

export async function deviceRoutes(app: FastifyInstance) {
  /** Lock / unlock / warn / restrict. */
  app.post('/api/devices/:id/state', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const b = z.object({
      state: z.enum(['unlocked', 'warning', 'restricted', 'locked']),
      reason: z.enum(LOCK_REASONS).default('overdue'),
      message: z.string().trim().max(300).optional(),
    }).parse(req.body);
    const r = await setLockState(id, mid, b.state, { user: u, reason: b.reason, message: b.message, log: req.log });
    const d = await getDevice(id, mid);
    return { ...r, smsTo: d.sim1_number };
  });

  /** Offline codes: the SMS text for the current state, to send from the shop phone. */
  app.get('/api/devices/:id/offline-code', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const d = await getDevice(id, mid);
    if (!d.command_key) throw conflict('Phone not enrolled yet');
    const state = d.status === 'released' ? 'released' : d.lock_state;
    return { state, sms: smsCommand(d.command_key, d.id, d.state_seq, state), smsTo: d.sim1_number };
  });

  app.post('/api/devices/:id/enrollment', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const b = z.object({ wifiSsid: z.string().max(64).optional(), wifiPassword: z.string().max(64).optional() }).default({}).parse(req.body ?? {});
    return issueEnrollment(id, mid, b);
  });

  /** Ask the phone for its location (logged; for theft and recovery). */
  app.post('/api/devices/:id/locate', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const b = z.object({ reason: z.string().trim().min(3).max(200) }).parse(req.body);
    const d = await getDevice(id, mid);
    if (d.status !== 'active') throw conflict('Phone is not active');
    await q('update devices set locate_requested = true where id = $1', [id]);
    await audit({ merchantId: mid, userId: u.id, action: 'device.locate', target: id, data: { reason: b.reason } });
    void pushSync(d.fcm_token, req.log);
    return { ok: true };
  });

  app.get('/api/devices/:id/locations', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    await getDevice(id, mid);
    return { items: await q('select lat, lng, accuracy, reason, created_at as "at" from locations where device_id = $1 order by created_at desc limit 200', [id]) };
  });

  app.get('/api/devices/:id/events', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    await getDevice(id, mid);
    const events = await q('select type, data, created_at as "at" from device_events where device_id = $1 order by created_at desc limit 100', [id]);
    const actions = await q(
      `select a.action, a.data, a.created_at as "at", u.name as "by" from audit_log a left join users u on u.id = a.user_id
       where a.target = $1 order by a.created_at desc limit 100`, [id]);
    return { events, actions };
  });

  app.post('/api/devices/:id/release', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const b = z.object({ force: z.boolean().default(false) }).parse(req.body ?? {});
    return requestRelease(id, mid, u, b.force, req.log);
  });

  /** Mark that the locker is gone from the phone (uninstalled, phone lost). Frees nothing; for records. */
  app.post('/api/devices/:id/mark-removed', async (req) => {
    const u = await requireUser(req);
    requireRole(u, 'owner', 'super_admin');
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    await getDevice(id, mid);
    await q("update devices set status = 'removed' where id = $1 and status in ('active','pending')", [id]);
    await audit({ merchantId: mid, userId: u.id, action: 'device.mark_removed', target: id });
    return { ok: true };
  });

  // ---- Reminders ----
  app.get('/api/devices/:id/reminders', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    await getDevice(id, mid);
    return { items: await q('select id, kind, channel, message, status, created_at as "at" from reminders where device_id = $1 order by created_at desc limit 100', [id]) };
  });

  app.post('/api/devices/:id/remind', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const b = z.object({ message: z.string().trim().min(5).max(300).optional() }).parse(req.body ?? {});
    const d = await one<any>(
      `select d.id, d.fcm_token, d.status, c.mobile, c.name, m.name as shop, m.phone as shop_phone
       from devices d join customers c on c.id = d.customer_id join merchants m on m.id = d.merchant_id where d.id = $1 and d.merchant_id = $2`, [id, mid]);
    if (!d) throw badRequest('Device not found');
    const sum = await loanSummary(id);
    const text = b.message ?? defaultReminder(d.name, d.shop, d.shop_phone, sum);
    const smsStatus = await sendSms(d.mobile, text);
    await q("insert into reminders(device_id, kind, channel, message, status) values ($1,'manual','sms',$2,$3)", [id, text, smsStatus]);
    if (d.status === 'active') {
      await q("insert into reminders(device_id, kind, channel, message, status) values ($1,'manual','device',$2,'queued')", [id, text]);
      void pushSync(d.fcm_token, req.log);
    }
    await audit({ merchantId: mid, userId: u.id, action: 'device.remind', target: id });
    return { ok: true, sms: smsStatus, text };
  });

  // ---- Payments ----
  app.post('/api/devices/:id/payments', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    const b = z.object({
      amount: z.number().positive().max(1_000_000),
      method: z.enum(['cash', 'upi', 'card', 'bank', 'other']),
      ref: z.string().trim().max(80).default(''),
    }).parse(req.body);
    const result = await recordPayment(id, mid, b.amount, b.method, b.ref, u.id, req.log);
    return result;
  });
}

export function defaultReminder(name: string, shop: string, phone: string, sum: Awaited<ReturnType<typeof loanSummary>>) {
  if (!sum) return `Dear ${name}, please contact ${shop} ${phone}.`;
  if (sum.overdueAmount > 0) return `Dear ${name}, your EMI of Rs ${sum.overdueAmount} is overdue by ${sum.overdueDays} days. Please pay at ${shop} or call ${phone} to avoid phone restriction.`;
  return `Dear ${name}, your next EMI of Rs ${sum.nextDueAmount} is due on ${sum.nextDueDate}. ${shop} ${phone}`;
}

/** Records a payment and unlocks the phone automatically when nothing is overdue any more. */
export async function recordPayment(deviceId: string, merchantId: string, amount: number, method: string, ref: string, userId: string | null, log?: any) {
  const d = await getDevice(deviceId, merchantId);
  const loan = await one<{ id: string; status: string }>('select id, status from loans where device_id = $1', [deviceId]);
  if (!loan) throw badRequest('No loan for this phone');
  if (loan.status === 'closed') throw conflict('This loan is already fully paid');
  const res = await tx(async (c) => {
    const r = await applyPayment(loan.id, amount, method, ref, userId, c);
    await audit({ merchantId, userId, action: 'payment.record', target: deviceId, data: { amount, method, ref, applied: r.applied } }, c);
    return r;
  });
  const sum = await loanSummary(deviceId);
  const m = await one<{ settings: any }>('select settings from merchants where id = $1', [merchantId]);
  let unlocked = false;
  const autoUnlock = (m?.settings?.autoUnlockOnPayment ?? true) && d.lock_reason !== 'theft' && d.lock_reason !== 'tamper';
  if (d.status === 'active' && d.lock_state !== 'unlocked' && autoUnlock && sum && sum.overdueAmount === 0) {
    await setLockState(deviceId, merchantId, 'unlocked', { user: null, reason: 'paid', skipRules: true, log });
    unlocked = true;
  }
  return { ...res, unlocked, summary: sum };
}
