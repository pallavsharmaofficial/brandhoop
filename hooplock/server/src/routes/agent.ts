import type { FastifyInstance } from 'fastify';
import { randomBytes } from 'node:crypto';
import { z } from 'zod';
import { config } from '../config.js';
import { one, q, tx } from '../db.js';
import { requireDevice } from '../auth.js';
import { badRequest, conflict, HttpError } from '../errors.js';
import { randomToken, sha256 } from '../security.js';
import { audit } from '../services/audit.js';
import { signedStateFor } from '../services/devices.js';

const simSchema = z.object({ number: z.string().max(20).default(''), operator: z.string().max(40).default(''), iccidHash: z.string().max(80).default('') });

const deviceInfo = z.object({
  imei1: z.string().max(20).default(''),
  imei2: z.string().max(20).default(''),
  serial: z.string().max(40).default(''),
  brand: z.string().max(40).default(''),
  model: z.string().max(60).default(''),
  osVersion: z.string().max(20).default(''),
  agentVersion: z.string().max(20).default(''),
  sims: z.array(simSchema).max(2).default([]),
  fcmToken: z.string().max(4096).optional(),
});

const locationSchema = z.object({ lat: z.number().min(-90).max(90), lng: z.number().min(-180).max(180), accuracy: z.number().min(0).max(100000).optional(), reason: z.string().max(40).default('') });

/** Endpoints the locker app on the customer's phone talks to. */
export async function agentRoutes(app: FastifyInstance) {
  app.post('/agent/v1/enroll', { config: { rateLimit: { max: 20, timeWindow: '1 minute' } } }, async (req) => {
    const b = deviceInfo.extend({ token: z.string().min(10).max(100) }).parse(req.body);
    const apiToken = randomToken(32);
    const commandKey = randomBytes(32).toString('hex');
    const deviceId = await tx(async (c) => {
      const t = await one<{ device_id: string; merchant_id: string; expires_at: Date; used_at: Date | null }>(
        'select * from enrollment_tokens where token = $1 for update', [b.token], c);
      if (!t) throw badRequest('This QR code is not valid');
      if (t.used_at) throw conflict('This QR code was already used. Make a new one in the app.');
      if (t.expires_at < new Date()) throw badRequest('This QR code has expired. Make a new one in the app.');
      const d = await one<{ status: string; platform: string }>('select status, platform from devices where id = $1 for update', [t.device_id], c);
      if (d?.status !== 'pending') throw conflict('This sale already has an enrolled phone');
      // One key per enrolled phone, taken only when the phone really checks in.
      const k = await one('update merchants set android_keys = android_keys - 1 where id = $1 and android_keys > 0 returning android_keys', [t.merchant_id], c);
      if (!k) throw new HttpError(402, 'The shop has no keys left', 'no_keys');
      await q("insert into key_ledger(merchant_id, platform, delta, reason, device_id) values ($1,'android',-1,'enroll',$2)", [t.merchant_id, t.device_id], c);
      await q('update enrollment_tokens set used_at = now() where token = $1', [b.token], c);
      const sim1 = b.sims[0]; const sim2 = b.sims[1];
      await q(
        `update devices set status = 'active', enrolled_at = now(), last_seen_at = now(), api_token_hash = $2, command_key = $3,
           imei1 = coalesce(nullif($4,''), imei1), imei2 = coalesce(nullif($5,''), imei2), serial = coalesce(nullif($6,''), serial),
           brand = coalesce(nullif($7,''), brand), model = coalesce(nullif($8,''), model), os_version = $9, agent_version = $10,
           sim1_number = coalesce(nullif($11,''), sim1_number), sim1_operator = $12, sim2_number = $13, sim2_operator = $14, fcm_token = $15,
           state_seq = state_seq + 1
         where id = $1`,
        [t.device_id, sha256(apiToken), commandKey, b.imei1, b.imei2, b.serial, b.brand, b.model, b.osVersion, b.agentVersion,
          sim1?.number ?? '', sim1?.operator ?? '', sim2?.number ?? '', sim2?.operator ?? '', b.fcmToken ?? null], c);
      await q("insert into device_events(device_id, type, data) values ($1,'enrolled',$2)", [t.device_id, JSON.stringify({ sims: b.sims.map((s) => s.iccidHash) })], c);
      await audit({ merchantId: t.merchant_id, userId: null, action: 'device.enrolled', target: t.device_id, data: { model: b.model, imei1: b.imei1 } }, c);
      return t.device_id;
    });
    const fcm = config.fcmClient.projectId ? config.fcmClient : null;
    return { deviceId, apiToken, commandKey, state: await signedStateFor(deviceId), fcm, syncMinutes: 15 };
  });

  /** Customer accepted the agreement on the phone during setup. */
  app.post('/agent/v1/consent', async (req) => {
    const dev = await requireDevice(req);
    const b = z.object({ acceptedAt: z.number().int(), language: z.string().max(5).default('en') }).parse(req.body);
    await q('update loans set consent_at = coalesce(consent_at, to_timestamp($2)) where device_id = $1', [dev.id, b.acceptedAt]);
    await q("insert into device_events(device_id, type, data) values ($1,'consent',$2)", [dev.id, JSON.stringify(b)]);
    return { ok: true };
  });

  /** Heartbeat: phone reports status, gets its signed state and any notices. */
  app.post('/agent/v1/sync', async (req) => {
    const dev = await requireDevice(req);
    const b = deviceInfo.partial().extend({
      appliedSeq: z.number().int().min(0),
      appliedState: z.string().max(20),
      battery: z.number().int().min(0).max(100).optional(),
      location: locationSchema.optional(),
      events: z.array(z.object({ type: z.string().max(40), data: z.record(z.unknown()).default({}), at: z.number().int().optional() })).max(50).default([]),
    }).parse(req.body);

    const prev = await one<{ sim1_number: string; status: string }>('select sim1_number, status from devices where id = $1', [dev.id]);
    const sim1 = b.sims?.[0]; const sim2 = b.sims?.[1];
    await q(
      `update devices set last_seen_at = now(), reported_state = $2, battery = coalesce($3, battery),
         fcm_token = coalesce($4, fcm_token), agent_version = coalesce($5, agent_version), os_version = coalesce($6, os_version),
         sim1_operator = coalesce($7, sim1_operator), sim2_number = coalesce($8, sim2_number), sim2_operator = coalesce($9, sim2_operator),
         status = case when status = 'removed' then 'active' else status end
       where id = $1`,
      [dev.id, b.appliedState, b.battery ?? null, b.fcmToken ?? null, b.agentVersion ?? null, b.osVersion ?? null,
        sim1?.operator ?? null, sim2?.number ?? null, sim2?.operator ?? null]);
    for (const e of b.events) {
      await q('insert into device_events(device_id, type, data, created_at) values ($1,$2,$3, coalesce(to_timestamp($4), now()))',
        [dev.id, e.type, JSON.stringify(e.data), e.at ?? null]);
      if (e.type === 'admin_disabled' || e.type === 'uninstall_attempt') {
        await audit({ merchantId: dev.merchantId, userId: null, action: 'device.tamper', target: dev.id, data: e });
      }
    }
    if (prev?.status === 'removed') await q("insert into device_events(device_id, type) values ($1,'back_online')", [dev.id]);
    if (b.location) {
      await q('insert into locations(device_id, lat, lng, accuracy, reason) values ($1,$2,$3,$4,$5)',
        [dev.id, b.location.lat, b.location.lng, b.location.accuracy ?? null, b.location.reason || 'sync']);
      await q('update devices set locate_requested = false where id = $1', [dev.id]);
    }
    const notices = await q<{ id: number; message: string }>(
      "update reminders set status = 'delivered' where device_id = $1 and channel = 'device' and status = 'queued' returning id, message", [dev.id]);
    return { state: await signedStateFor(dev.id), notices };
  });

  app.post('/agent/v1/location', async (req) => {
    const dev = await requireDevice(req);
    const b = locationSchema.parse(req.body);
    await q('insert into locations(device_id, lat, lng, accuracy, reason) values ($1,$2,$3,$4,$5)', [dev.id, b.lat, b.lng, b.accuracy ?? null, b.reason || 'push']);
    await q('update devices set locate_requested = false where id = $1', [dev.id]);
    return { ok: true };
  });

  /** Phone confirms it removed every restriction and is uninstalling itself. */
  app.post('/agent/v1/released', async (req) => {
    const dev = await requireDevice(req);
    await q("update devices set released_at = now(), api_token_hash = null, fcm_token = null where id = $1 and status = 'released'", [dev.id]);
    await q("insert into device_events(device_id, type) values ($1,'released')", [dev.id]);
    return { ok: true };
  });
}
