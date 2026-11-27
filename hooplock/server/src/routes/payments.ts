import type { FastifyInstance } from 'fastify';
import { createHmac } from 'node:crypto';
import { z } from 'zod';
import { config } from '../config.js';
import { one } from '../db.js';
import { merchantScope, requireUser } from '../auth.js';
import { badRequest, unauthorized } from '../errors.js';
import { safeEqual } from '../security.js';
import { getDevice } from '../services/devices.js';
import { loanSummary } from '../services/loans.js';
import { recordPayment } from './devices.js';

/**
 * Razorpay payment links: the shop sends the customer a link (also shown as a QR on the lock
 * screen); when Razorpay confirms the payment by webhook, the EMI is marked paid and the phone
 * unlocks by itself. Needs RAZORPAY_KEY_ID / SECRET / WEBHOOK_SECRET.
 */
export async function paymentRoutes(app: FastifyInstance) {
  app.post('/api/devices/:id/payment-link', async (req) => {
    const u = await requireUser(req);
    const mid = merchantScope(req, u);
    const { id } = req.params as { id: string };
    if (!config.razorpay.keyId) throw badRequest('Online payment links are not set up yet (Razorpay keys missing)');
    const b = z.object({ amount: z.number().positive().optional() }).parse(req.body ?? {});
    const d = await getDevice(id, mid);
    const c = await one<{ name: string; mobile: string }>('select name, mobile from customers where id = $1', [d.customer_id]);
    const sum = await loanSummary(id);
    const amount = b.amount ?? (sum?.overdueAmount || sum?.nextDueAmount || 0);
    if (amount <= 0) throw badRequest('Nothing is due');
    const r = await fetch('https://api.razorpay.com/v1/payment_links', {
      method: 'POST',
      headers: {
        authorization: 'Basic ' + Buffer.from(`${config.razorpay.keyId}:${config.razorpay.keySecret}`).toString('base64'),
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        amount: Math.round(amount * 100), currency: 'INR', description: 'EMI payment',
        customer: { name: c!.name, contact: '+91' + c!.mobile }, notify: { sms: true },
        notes: { device_id: id, merchant_id: mid },
      }),
    });
    if (!r.ok) throw badRequest('Razorpay did not create the link: ' + (await r.text()).slice(0, 200));
    const j = (await r.json()) as { short_url: string; id: string };
    return { url: j.short_url, id: j.id, amount };
  });

  app.post('/api/webhooks/razorpay', { config: { rawBody: true } }, async (req) => {
    if (!config.razorpay.webhookSecret) throw unauthorized('Webhook not configured');
    const raw = (req as any).rawBody as string;
    const sig = String(req.headers['x-razorpay-signature'] ?? '');
    const expected = createHmac('sha256', config.razorpay.webhookSecret).update(raw).digest('hex');
    if (!safeEqual(sig, expected)) throw unauthorized('Bad signature');
    const evt = JSON.parse(raw);
    if (evt.event !== 'payment_link.paid') return { ok: true, ignored: evt.event };
    const link = evt.payload?.payment_link?.entity;
    const payment = evt.payload?.payment?.entity;
    const deviceId = link?.notes?.device_id; const merchantId = link?.notes?.merchant_id;
    if (!deviceId || !merchantId || !payment) return { ok: true, ignored: 'no notes' };
    // Idempotent: Razorpay retries webhooks.
    const seen = await one("select 1 from audit_log where action = 'payment.record' and data->>'ref' = $1", [payment.id]);
    if (seen) return { ok: true, duplicate: true };
    await recordPayment(deviceId, merchantId, payment.amount / 100, 'upi', payment.id, null, req.log);
    return { ok: true };
  });
}
