import { config } from '../config.js';
import { one, q, type Db, pool } from '../db.js';
import { badRequest, conflict, forbidden, notFound } from '../errors.js';
import { randomToken, signState, smsCommand, type LockState } from '../security.js';
import type { AuthUser } from '../auth.js';
import { audit } from './audit.js';
import { pushSync } from './fcm.js';
import { loanSummary, todayIST, addMonths } from './loans.js';
import { settingsOf } from './settings.js';
import { iosApplyLock, iosRelease, mdmEnabled } from './mdm.js';

export interface DeviceRow {
  id: string; merchant_id: string; customer_id: string; platform: 'android' | 'ios';
  status: 'pending' | 'active' | 'released' | 'removed';
  lock_state: LockState; lock_reason: string; lock_message: string; state_seq: number;
  command_key: string | null; fcm_token: string | null; sim1_number: string; released_at: string | null;
}

export const LOCK_REASONS = ['overdue', 'theft', 'tamper', 'customer_request', 'auto', 'other'] as const;

export async function getDevice(id: string, merchantId: string, db: Db = pool): Promise<DeviceRow> {
  const d = await one<DeviceRow>('select * from devices where id = $1 and merchant_id = $2', [id, merchantId], db);
  if (!d) throw notFound('Device not found');
  return d;
}

const rank: Record<LockState, number> = { unlocked: 0, warning: 1, restricted: 2, locked: 3 };

/**
 * Changes what the phone must do. Bumps state_seq so the phone accepts the new state and
 * rejects any older one, records the reason, pushes a sync, and returns an SMS code for phones
 * that are offline.
 */
export async function setLockState(
  deviceId: string,
  merchantId: string,
  next: LockState,
  opts: { user: AuthUser | null; reason: string; message?: string; skipRules?: boolean; log?: any },
): Promise<{ seq: number; sms: string | null; changed: boolean }> {
  const d = await getDevice(deviceId, merchantId);
  if (d.status === 'released') throw conflict('This phone is already released');
  if (d.status === 'removed') throw conflict('The locker app is no longer on this phone');
  if (d.platform === 'ios') {
    if (!mdmEnabled()) throw conflict('iPhone locking needs the iPhone management server (Apple Business Manager + MDM). Not set up yet.');
    if (next === 'warning' || next === 'restricted') throw badRequest('iPhones support Lock and Unlock only. Send a reminder instead.');
    if (d.status !== 'active') throw conflict('This iPhone has not enrolled yet');
  }

  if (!opts.skipRules && rank[next] > rank[d.lock_state]) {
    const m = await one<{ settings: unknown }>('select settings from merchants where id = $1', [merchantId]);
    const s = settingsOf(m?.settings);
    const sum = await loanSummary(deviceId);
    const emergency = opts.reason === 'theft' || opts.reason === 'tamper';
    if ((next === 'restricted' || next === 'locked') && s.lockRequiresOverdue && !emergency && (!sum || sum.overdueDays <= 0)) {
      throw badRequest('No EMI is overdue. A lock is only allowed after a missed EMI (or for theft / tamper).');
    }
    if (next === 'locked' && s.lockNeedsOwner && opts.user?.role === 'staff') throw forbidden('Only the owner can fully lock a phone');
  }

  const changed = d.lock_state !== next || (opts.message ?? d.lock_message) !== d.lock_message;
  const row = await one<{ state_seq: number; command_key: string | null; fcm_token: string | null }>(
    `update devices set lock_state = $2, lock_reason = $3, lock_message = coalesce($4, lock_message), state_seq = state_seq + 1
     where id = $1 returning state_seq, command_key, fcm_token`,
    [deviceId, next, next === 'unlocked' ? '' : opts.reason, opts.message ?? null]);
  await audit({ merchantId, userId: opts.user?.id ?? null, action: `device.${next}`, target: deviceId, data: { reason: opts.reason, message: opts.message } });
  if (d.platform === 'ios') {
    const m = await one<{ name: string; phone: string }>('select name, phone from merchants where id = $1', [merchantId]);
    await iosApplyLock(deviceId, next as 'locked' | 'unlocked', m!, opts.message ?? d.lock_message);
    return { seq: row!.state_seq, sms: null, changed };
  }
  void pushSync(row!.fcm_token, opts.log);
  const sms = row!.command_key ? smsCommand(row!.command_key, deviceId, row!.state_seq, next) : null;
  return { seq: row!.state_seq, sms, changed };
}

export async function requestRelease(deviceId: string, merchantId: string, user: AuthUser, force: boolean, log?: any) {
  const d = await getDevice(deviceId, merchantId);
  if (d.status === 'released') return { sms: null };
  const sum = await loanSummary(deviceId);
  if (sum && sum.status !== 'closed' && !force) throw badRequest(`Loan still has ₹${sum.balance} to pay. Close it first, or release anyway as owner.`);
  if (force && user.role === 'staff') throw forbidden('Only the owner can release a phone with money still due');
  const row = await one<{ state_seq: number; command_key: string | null; fcm_token: string | null }>(
    `update devices set status = 'released', lock_state = 'unlocked', lock_reason = '', state_seq = state_seq + 1
     where id = $1 returning state_seq, command_key, fcm_token`, [deviceId]);
  await audit({ merchantId, userId: user.id, action: 'device.release', target: deviceId, data: { force } });
  if (d.platform === 'ios') {
    if (mdmEnabled() && d.status === 'active') await iosRelease(deviceId);
    else await q("update devices set released_at = now() where id = $1", [deviceId]);
    return { sms: null, appleBusinessManager: 'Also release this serial number from Apple Business Manager (Devices > Release).' };
  }
  void pushSync(row!.fcm_token, log);
  return { sms: row!.command_key ? smsCommand(row!.command_key, deviceId, row!.state_seq, 'released') : null };
}

export function upiLink(upiId: string, shop: string, amount: number | null, note: string) {
  if (!upiId) return '';
  const p = new URLSearchParams({ pa: upiId, pn: shop, cu: 'INR', tn: note });
  if (amount && amount > 0) p.set('am', amount.toFixed(2));
  return `upi://pay?${p.toString()}`;
}

/** The signed instruction set the phone applies on every sync. */
export async function signedStateFor(deviceId: string, db: Db = pool) {
  const d = await one<any>(
    `select d.*, m.name as shop_name, m.phone as shop_phone, m.call_numbers, m.upi_id, m.settings, c.name as customer_name
     from devices d join merchants m on m.id = d.merchant_id join customers c on c.id = d.customer_id where d.id = $1`, [deviceId], db);
  if (!d?.command_key) throw notFound('Device not enrolled');
  const s = settingsOf(d.settings);
  const sum = await loanSummary(deviceId, db);
  const today = todayIST();
  let noContactLockAt: number | null = null;
  if (d.status === 'active' && sum && sum.status === 'open' && sum.nextDueDate) {
    const base = sum.nextDueDate < today ? today : sum.nextDueDate;
    const day = addDays(base, s.noContactDays);
    noContactLockAt = Math.floor(Date.parse(day + 'T00:00:00+05:30') / 1000);
  }
  const callNumbers = Array.from(new Set([d.shop_phone, ...(d.call_numbers ?? [])].filter(Boolean)));
  const dueAmount = sum ? (sum.overdueAmount || sum.nextDueAmount || 0) : 0;
  const state = {
    v: 1,
    d: d.id,
    s: d.state_seq,
    st: d.lock_state as LockState,
    rel: d.status === 'released',
    msg: d.lock_message || '',
    shop: { name: d.shop_name, phone: d.shop_phone },
    calls: callNumbers,
    dues: sum ? { amount: dueAmount, overdueDays: sum.overdueDays, next: sum.nextDueDate, balance: sum.balance } : null,
    upi: upiLink(d.upi_id, d.shop_name, dueAmount, `EMI ${d.customer_name}`.slice(0, 50)),
    ncl: noContactLockAt,
    loc: d.locate_requested || d.lock_state === 'locked',
    frp: s.frpAccountIds,
    t: Math.floor(Date.now() / 1000),
  };
  return signState(d.command_key, state);
}

function addDays(iso: string, n: number) {
  const t = new Date(iso + 'T00:00:00Z');
  t.setUTCDate(t.getUTCDate() + n);
  return t.toISOString().slice(0, 10);
}

/** New single-use enrollment token (30 minutes) and the Android provisioning QR payload. */
export async function issueEnrollment(deviceId: string, merchantId: string, opts: { wifiSsid?: string; wifiPassword?: string } = {}) {
  const d = await getDevice(deviceId, merchantId);
  if (d.platform !== 'android') throw badRequest('QR enrollment is for Android phones');
  if (d.status !== 'pending') throw conflict('This phone is already enrolled');
  const token = randomToken(18);
  const expiresAt = new Date(Date.now() + 30 * 60_000);
  await q('insert into enrollment_tokens(token, merchant_id, device_id, expires_at) values ($1,$2,$3,$4)', [token, merchantId, deviceId, expiresAt]);
  return { token, expiresAt: expiresAt.toISOString(), qr: provisioningPayload(token, opts) };
}

export function provisioningPayload(token: string, opts: { wifiSsid?: string; wifiPassword?: string } = {}) {
  const p: Record<string, unknown> = {
    'android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME': config.agentComponent,
    'android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION': config.agentApkUrl || `${config.publicUrl}/agent/hooplock-agent.apk`,
    'android.app.extra.PROVISIONING_DEVICE_ADMIN_SIGNATURE_CHECKSUM': config.agentSignatureChecksum,
    'android.app.extra.PROVISIONING_LEAVE_ALL_SYSTEM_APPS_ENABLED': true,
    'android.app.extra.PROVISIONING_ADMIN_EXTRAS_BUNDLE': { server: config.publicUrl, token },
  };
  if (opts.wifiSsid) {
    p['android.app.extra.PROVISIONING_WIFI_SSID'] = opts.wifiSsid;
    p['android.app.extra.PROVISIONING_WIFI_SECURITY_TYPE'] = opts.wifiPassword ? 'WPA' : 'NONE';
    if (opts.wifiPassword) p['android.app.extra.PROVISIONING_WIFI_PASSWORD'] = opts.wifiPassword;
  }
  return JSON.stringify(p);
}
