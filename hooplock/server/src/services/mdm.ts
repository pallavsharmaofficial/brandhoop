import { randomUUID } from 'node:crypto';
import plist from 'plist';
import { config } from '../config.js';
import { one, q, tx } from '../db.js';
import { conflict } from '../errors.js';
import { audit } from './audit.js';

/**
 * iPhone locking through NanoMDM (open-source Apple MDM server, run next to this API).
 *
 * Needs: the iPhone added to the shop's Apple Business Manager and assigned to the MDM server, so it
 * enrolls supervised during setup. Then:
 *   locked   -> EnableLostMode (full-screen message + shop phone; only emergency calls)
 *   unlocked -> DisableLostMode
 *   locate   -> DeviceLocation (Apple allows it only in Lost Mode)
 *   always   -> restrictions profile: no "Erase All Content and Settings"
 * Warning / restricted have no iOS equivalent: the customer gets reminders instead.
 */
export const mdmEnabled = () => Boolean(config.nanomdm.url && config.nanomdm.apiKey);

const BASE_PROFILE_ID = 'in.hooplock.base';

function commandPlist(uuid: string, command: Record<string, unknown>): string {
  return plist.build({ Command: command, CommandUUID: uuid } as any);
}

function baseProfile(): Buffer {
  const restrictions = {
    PayloadType: 'com.apple.applicationaccess',
    PayloadVersion: 1,
    PayloadIdentifier: `${BASE_PROFILE_ID}.restrictions`,
    PayloadUUID: '6F3C1E2A-8B5D-4C0E-9A1F-2D3B4C5D6E7F',
    PayloadDisplayName: 'EMI protection',
    allowEraseContentAndSettings: false,
    allowUIConfigurationProfileInstallation: false,
    allowFindMyDeviceModification: false,
  };
  return Buffer.from(plist.build({
    PayloadType: 'Configuration',
    PayloadVersion: 1,
    PayloadIdentifier: BASE_PROFILE_ID,
    PayloadUUID: '1A2B3C4D-5E6F-4A8B-9C0D-1E2F3A4B5C6D',
    PayloadDisplayName: 'HoopLock EMI protection',
    PayloadDescription: 'Keeps this financed iPhone protected until all EMIs are paid.',
    PayloadRemovalDisallowed: true,
    PayloadContent: [restrictions],
  } as any));
}

async function nano(path: string, method: string, body?: string): Promise<Response> {
  const auth = 'Basic ' + Buffer.from(`nanomdm:${config.nanomdm.apiKey}`).toString('base64');
  let last: Response | undefined;
  for (let attempt = 0; attempt < 3; attempt++) {
    last = await fetch(config.nanomdm.url.replace(/\/$/, '') + path, { method, headers: { authorization: auth, 'content-type': 'application/xml' }, body });
    if (last.status !== 429 && last.status < 500) return last;
    await new Promise((r) => setTimeout(r, 300 * 2 ** attempt));
  }
  return last!;
}

/** Queues one command for the iPhone and asks Apple (APNs) to wake it. */
export async function enqueue(deviceId: string, command: Record<string, unknown>): Promise<string> {
  if (!mdmEnabled()) throw conflict('iPhone management server is not set up yet');
  const d = await one<{ mdm_udid: string | null }>('select mdm_udid from devices where id = $1', [deviceId]);
  if (!d?.mdm_udid) throw conflict('This iPhone has not enrolled yet. Set it up from Apple Business Manager first.');
  const uuid = randomUUID();
  await q('insert into mdm_commands(uuid, device_id, request_type) values ($1,$2,$3)', [uuid, deviceId, String(command.RequestType)]);
  const r = await nano(`/v1/enqueue/${encodeURIComponent(d.mdm_udid)}`, 'PUT', commandPlist(uuid, command));
  if (!r.ok) {
    await q("update mdm_commands set status = 'failed', error = $2 where uuid = $1", [uuid, `HTTP ${r.status}`]);
    throw conflict(`iPhone server refused the command (HTTP ${r.status})`);
  }
  return uuid;
}

export async function iosApplyLock(deviceId: string, state: 'locked' | 'unlocked', shop: { name: string; phone: string }, message: string) {
  if (state === 'locked') {
    return enqueue(deviceId, {
      RequestType: 'EnableLostMode',
      Message: message || `EMI payment pending. Please contact ${shop.name}.`,
      PhoneNumber: shop.phone,
      Footnote: shop.name,
    });
  }
  return enqueue(deviceId, { RequestType: 'DisableLostMode' });
}

export const iosLocate = (deviceId: string) => enqueue(deviceId, { RequestType: 'DeviceLocation' });

export async function iosRelease(deviceId: string) {
  await enqueue(deviceId, { RequestType: 'DisableLostMode' }).catch(() => undefined);
  return enqueue(deviceId, { RequestType: 'RemoveProfile', Identifier: BASE_PROFILE_ID });
}

function decode(raw?: string): Record<string, any> {
  if (!raw) return {};
  try { return plist.parse(Buffer.from(raw, 'base64').toString('utf8')) as Record<string, any>; } catch { return {}; }
}

/**
 * Events from NanoMDM (its -webhook-url, MicroMDM-style JSON).
 * Authenticate: links the device UDID to the sale by serial number.
 * TokenUpdate (first): enrollment finished -> active, one iOS key used, protection profile installed.
 * CheckOut: management removed. Acknowledge: command results (location).
 */
export async function handleWebhook(evt: any) {
  const topic: string = evt?.topic ?? '';
  const checkin = evt?.checkin_event;
  const ack = evt?.acknowledge_event;
  const udid: string | undefined = checkin?.udid ?? ack?.udid;
  if (!udid) return { ignored: true };

  if (topic === 'mdm.Authenticate') {
    const p = decode(checkin.raw_payload);
    const serial = String(p.SerialNumber ?? '').toUpperCase();
    if (!serial) return { ignored: 'no serial' };
    const d = await one<{ id: string }>(
      "select id from devices where platform = 'ios' and upper(serial) = $1 and status in ('pending','active','removed') order by created_at desc limit 1", [serial]);
    if (!d) return { ignored: 'unknown serial' };
    await q('update devices set mdm_udid = null where mdm_udid = $1 and id <> $2', [udid, d.id]);
    await q("update devices set mdm_udid = $2, model = coalesce(nullif($3,''), model), os_version = coalesce(nullif($4,''), os_version), imei1 = coalesce(nullif($5,''), imei1) where id = $1",
      [d.id, udid, String(p.ProductName ?? ''), String(p.OSVersion ?? ''), String(p.IMEI ?? '').replace(/\s/g, '')]);
    return { linked: d.id };
  }

  const d = await one<{ id: string; merchant_id: string; status: string; lock_state: string; lock_message: string; mdm_enrolled_at: string | null }>(
    'select id, merchant_id, status, lock_state, lock_message, mdm_enrolled_at from devices where mdm_udid = $1', [udid]);
  if (!d) return { ignored: 'unknown device' };
  await q('update devices set last_seen_at = now() where id = $1', [d.id]);

  if (topic === 'mdm.TokenUpdate' && !d.mdm_enrolled_at) {
    const activated = await tx(async (c) => {
      const k = await one('update merchants set ios_keys = ios_keys - 1 where id = $1 and ios_keys > 0 returning ios_keys', [d.merchant_id], c);
      if (!k) return false;
      await q("insert into key_ledger(merchant_id, platform, delta, reason, device_id) values ($1,'ios',-1,'enroll',$2)", [d.merchant_id, d.id], c);
      await q("update devices set status = 'active', mdm_enrolled_at = now(), enrolled_at = now(), state_seq = state_seq + 1 where id = $1", [d.id], c);
      await q("insert into device_events(device_id, type) values ($1,'enrolled')", [d.id], c);
      await audit({ merchantId: d.merchant_id, userId: null, action: 'device.enrolled', target: d.id, data: { platform: 'ios' } }, c);
      return true;
    });
    if (!activated) {
      await q("insert into device_events(device_id, type, data) values ($1,'enroll_blocked','{\"reason\":\"no iOS keys\"}')", [d.id]);
      return { blocked: 'no keys' };
    }
    await enqueue(d.id, { RequestType: 'InstallProfile', Payload: baseProfile() });
    if (d.lock_state === 'locked') {
      const m = await one<{ name: string; phone: string }>('select name, phone from merchants where id = $1', [d.merchant_id]);
      await iosApplyLock(d.id, 'locked', m!, d.lock_message);
    }
    return { activated: d.id };
  }

  if (topic === 'mdm.CheckOut') {
    await q("update devices set status = case when status = 'released' then status else 'removed' end where id = $1", [d.id]);
    await q("insert into device_events(device_id, type) values ($1,'mdm_removed')", [d.id]);
    if (d.status !== 'released') await audit({ merchantId: d.merchant_id, userId: null, action: 'device.tamper', target: d.id, data: { reason: 'MDM removed' } });
    return { removed: d.id };
  }

  if (ack?.command_uuid) {
    const p = decode(ack.raw_payload);
    await q('update mdm_commands set status = $2, acked_at = now(), error = $3 where uuid = $1',
      [ack.command_uuid, ack.status ?? 'Acknowledged', p.ErrorChain ? JSON.stringify(p.ErrorChain).slice(0, 500) : null]);
    if (typeof p.Latitude === 'number' && typeof p.Longitude === 'number') {
      await q("insert into locations(device_id, lat, lng, accuracy, reason) values ($1,$2,$3,$4,'lost_mode')",
        [d.id, p.Latitude, p.Longitude, p.HorizontalAccuracy ?? null]);
      await q('update devices set locate_requested = false where id = $1', [d.id]);
    }
    const cmd = await one<{ request_type: string }>('select request_type from mdm_commands where uuid = $1', [ack.command_uuid]);
    if (cmd?.request_type === 'RemoveProfile' && ack.status === 'Acknowledged') {
      await q("update devices set released_at = now() where id = $1 and status = 'released'", [d.id]);
      await q("insert into device_events(device_id, type) values ($1,'released')", [d.id]);
    }
    if (cmd?.request_type === 'EnableLostMode' || cmd?.request_type === 'DisableLostMode') {
      await q('update devices set reported_state = $2 where id = $1', [d.id, cmd.request_type === 'EnableLostMode' ? 'locked' : 'unlocked']);
    }
    return { ack: ack.command_uuid };
  }
  return { ok: true };
}
