import { beforeAll, afterAll, describe, expect, it } from 'vitest';
import { createHmac } from 'node:crypto';

process.env.DATABASE_URL = process.env.TEST_DATABASE_URL ?? 'postgres://hooplock:hooplock@localhost:5432/hooplock_test';
process.env.PUBLIC_URL = 'https://lock.example.in';
process.env.AGENT_SIGNATURE_CHECKSUM = 'abc123';

const { buildApp } = await import('../src/app.js');
const { pool, q } = await import('../src/db.js');
const { migrate } = await import('../src/migrate.js');
const { hashPassword } = await import('../src/security.js');
const { runDaily } = await import('../src/services/scheduler.js');
const { addMonths, todayIST } = await import('../src/services/loans.js');

let app: Awaited<ReturnType<typeof buildApp>>;
let adminToken = '';
let ownerToken = '';
let staffToken = '';
let merchantId = '';

async function call(method: string, url: string, token?: string, body?: unknown, extra: Record<string, string> = {}) {
  const r = await app.inject({
    method: method as any, url,
    headers: { ...(token ? { authorization: token.startsWith('Device') ? token : `Bearer ${token}` } : {}), ...extra },
    payload: body as any,
  });
  return { status: r.statusCode, body: r.headers['content-type']?.includes('json') ? r.json() : r.body };
}

function verify(key: string, s: { payload: string; sig: string }) {
  const expected = createHmac('sha256', Buffer.from(key, 'hex')).update(s.payload).digest('base64url');
  expect(s.sig).toBe(expected);
  return JSON.parse(s.payload);
}

beforeAll(async () => {
  await pool.query('drop schema public cascade; create schema public;');
  await migrate();
  await q("insert into users(role, name, phone, password_hash) values ('super_admin','Pallav','9999999999',$1)", [await hashPassword('admin-pass-1')]);
  app = await buildApp({ logger: false });
});

afterAll(async () => { await app.close(); await pool.end(); });

describe('HoopLock end to end', () => {
  it('logs in the super admin and creates a shop with keys', async () => {
    const bad = await call('POST', '/api/auth/login', undefined, { phone: '9999999999', password: 'nope' });
    expect(bad.status).toBe(401);
    const r = await call('POST', '/api/auth/login', undefined, { phone: '9999999999', password: 'admin-pass-1' });
    expect(r.status).toBe(200);
    adminToken = r.body.token;
    const m = await call('POST', '/api/admin/merchants', adminToken, {
      name: 'Brand Hoop Neem Ka Thana', ownerName: 'Owner', phone: '9000000001', city: 'Neem Ka Thana',
      callNumbers: ['9000000009'], upiId: 'shop@upi', ownerPassword: 'owner-pass-1', androidKeys: 2, iosKeys: 0,
    });
    expect(m.status).toBe(200);
    merchantId = m.body.id;
    const o = await call('POST', '/api/auth/login', undefined, { phone: '9000000001', password: 'owner-pass-1' });
    ownerToken = o.body.token;
    const s = await call('POST', '/api/staff', ownerToken, { name: 'Staff', phone: '9000000003', password: 'staff-pass-1' });
    expect(s.status).toBe(200);
    staffToken = (await call('POST', '/api/auth/login', undefined, { phone: '9000000003', password: 'staff-pass-1' })).body.token;
  });

  it('keeps shops apart', async () => {
    const other = await call('POST', '/api/admin/merchants', adminToken, { name: 'Other', phone: '9000000100', ownerPassword: 'other-pass-1' });
    const o = await call('POST', '/api/auth/login', undefined, { phone: '9000000100', password: 'other-pass-1' });
    const list = await call('GET', '/api/customers', o.body.token);
    expect(list.body.items).toHaveLength(0);
    expect(other.status).toBe(200);
    const staffAdmin = await call('GET', '/api/admin/merchants', staffToken);
    expect(staffAdmin.status).toBe(403);
  });

  let deviceId = '';
  let enrollToken = '';
  let device: { deviceId: string; apiToken: string; commandKey: string } = { deviceId: '', apiToken: '', commandKey: '' };

  it('creates a credit sale with an EMI schedule and a provisioning QR', async () => {
    const today = todayIST();
    const r = await call('POST', '/api/sales', staffToken, {
      platform: 'android',
      customer: { name: 'Dinesh', mobile: '9887778181' },
      device: { brand: 'realme', model: 'RMX5270' },
      loan: { totalAmount: 30999, downPayment: 12500, emiAmount: 2642, emiCount: 7, firstEmiDate: addMonths(today, -2) },
    });
    expect(r.status).toBe(200);
    deviceId = r.body.deviceId;
    enrollToken = r.body.enrollment.token;
    const qr = JSON.parse(r.body.enrollment.qr);
    expect(qr['android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME']).toBe('in.hooplock.agent/.admin.HoopAdminReceiver');
    expect(qr['android.app.extra.PROVISIONING_DEVICE_ADMIN_SIGNATURE_CHECKSUM']).toBe('abc123');
    expect(qr['android.app.extra.PROVISIONING_ADMIN_EXTRAS_BUNDLE']).toEqual({ server: 'https://lock.example.in', token: enrollToken });
  });

  it('enrolls the phone once and takes one key', async () => {
    const info = { token: enrollToken, imei1: '867147081456635', brand: 'realme', model: 'RMX5270', osVersion: '15', agentVersion: '1.0.0', sims: [{ number: '9887778181', operator: 'airtel' }] };
    const r = await call('POST', '/agent/v1/enroll', undefined, info);
    expect(r.status).toBe(200);
    device = r.body;
    const st = verify(device.commandKey, r.body.state);
    expect(st.st).toBe('unlocked');
    expect(st.calls).toEqual(['9000000001', '9000000009']);
    expect(st.ncl).toBeTypeOf('number');
    const again = await call('POST', '/agent/v1/enroll', undefined, info);
    expect(again.status).toBe(409);
    const dash = await call('GET', '/api/dashboard', ownerToken);
    expect(dash.body.keys.android).toBe(1);
    expect(dash.body.devices.active).toBe(1);
  });

  it('shows overdue EMIs in the lists', async () => {
    const d = await call('GET', `/api/devices/${deviceId}`, ownerToken);
    expect(d.body.summary.overdueCount).toBe(2);
    expect(d.body.summary.overdueAmount).toBe(5284);
    const risk = await call('GET', '/api/customers?tab=high_risk', ownerToken);
    expect(risk.body.items.map((i: any) => i.deviceId)).toContain(deviceId);
    const search = await call('GET', '/api/customers?q=867147', ownerToken);
    expect(search.body.items).toHaveLength(1);
  });

  it('locks with a signed, higher sequence state and an SMS fallback code', async () => {
    const r = await call('POST', `/api/devices/${deviceId}/state`, staffToken, { state: 'locked', reason: 'overdue', message: 'Please pay your EMI' });
    expect(r.status).toBe(200);
    expect(r.body.sms).toMatch(/^HL1 \d+ L [A-Za-z0-9_-]{22}$/);
    const [, seq, code, sig] = r.body.sms.split(' ');
    const expected = createHmac('sha256', Buffer.from(device.commandKey, 'hex')).update(`HL1|${deviceId}|${seq}|${code}`).digest().subarray(0, 16).toString('base64url');
    expect(sig).toBe(expected);

    const sync = await call('POST', '/agent/v1/sync', `Device ${device.deviceId}.${device.apiToken}`, {
      appliedSeq: 1, appliedState: 'unlocked', battery: 80, location: { lat: 27.73, lng: 75.78, accuracy: 20, reason: 'locked' },
      events: [{ type: 'sim_changed', data: { slot: 1 } }],
    });
    expect(sync.status).toBe(200);
    const st = verify(device.commandKey, sync.body.state);
    expect(st.st).toBe('locked');
    expect(st.s).toBe(Number(seq));
    expect(st.msg).toBe('Please pay your EMI');
    expect(st.dues.amount).toBe(5284);
    expect(st.upi).toContain('upi://pay?pa=shop%40upi');
    const locs = await call('GET', `/api/devices/${deviceId}/locations`, ownerToken);
    expect(locs.body.items[0].lat).toBe(27.73);
  });

  it('rejects a bad device token', async () => {
    const r = await call('POST', '/agent/v1/sync', `Device ${device.deviceId}.wrong`, { appliedSeq: 1, appliedState: 'x' });
    expect(r.status).toBe(401);
  });

  it('unlocks automatically when overdue EMIs are paid', async () => {
    const part = await call('POST', `/api/devices/${deviceId}/payments`, staffToken, { amount: 3000, method: 'cash' });
    expect(part.body.unlocked).toBe(false);
    const rest = await call('POST', `/api/devices/${deviceId}/payments`, staffToken, { amount: 2284, method: 'upi', ref: 'UTR1' });
    expect(rest.body.unlocked).toBe(true);
    const d = await call('GET', `/api/devices/${deviceId}`, ownerToken);
    expect(d.body.lockState).toBe('unlocked');
    expect(d.body.summary.paidCount).toBe(2);
  });

  it('refuses a lock when nothing is overdue, except for theft', async () => {
    const r = await call('POST', `/api/devices/${deviceId}/state`, staffToken, { state: 'locked', reason: 'overdue' });
    expect(r.status).toBe(400);
    const t = await call('POST', `/api/devices/${deviceId}/state`, ownerToken, { state: 'locked', reason: 'theft' });
    expect(t.status).toBe(200);
    // payment does not unlock a theft lock
    await call('POST', `/api/devices/${deviceId}/payments`, staffToken, { amount: 100, method: 'cash' });
    expect((await call('GET', `/api/devices/${deviceId}`, ownerToken)).body.lockState).toBe('locked');
    await call('POST', `/api/devices/${deviceId}/state`, ownerToken, { state: 'unlocked', reason: 'other' });
  });

  it('scheduler warns, then restricts, after the configured overdue days', async () => {
    const future = addMonths(todayIST(), 1); // next EMI (seq 3, due today) will be overdue by ~30 days
    const r1 = await runDaily(undefined, future);
    expect(r1.steps).toBe(1);
    let d = await call('GET', `/api/devices/${deviceId}`, ownerToken);
    expect(['warning', 'restricted']).toContain(d.body.lockState);
    const later = addMonths(todayIST(), 2);
    await runDaily(undefined, later);
    d = await call('GET', `/api/devices/${deviceId}`, ownerToken);
    expect(d.body.lockState).toBe('restricted');
    const rem = await call('GET', `/api/devices/${deviceId}/reminders`, ownerToken);
    expect(rem.body.items.length).toBeGreaterThan(0);
  });

  it('releases only when the loan is closed, unless the owner forces it', async () => {
    const staff = await call('POST', `/api/devices/${deviceId}/release`, staffToken, {});
    expect(staff.status).toBe(400);
    const staffForce = await call('POST', `/api/devices/${deviceId}/release`, staffToken, { force: true });
    expect(staffForce.status).toBe(403);
    const sum = (await call('GET', `/api/devices/${deviceId}`, ownerToken)).body.summary;
    const pay = await call('POST', `/api/devices/${deviceId}/payments`, staffToken, { amount: sum.balance, method: 'cash' });
    expect(pay.body.closed).toBe(true);
    const rel = await call('POST', `/api/devices/${deviceId}/release`, staffToken, {});
    expect(rel.status).toBe(200);
    expect(rel.body.sms).toMatch(/ X /);
    const sync = await call('POST', '/agent/v1/sync', `Device ${device.deviceId}.${device.apiToken}`, { appliedSeq: 5, appliedState: 'unlocked' });
    const st = verify(device.commandKey, sync.body.state);
    expect(st.rel).toBe(true);
    expect(st.ncl).toBeNull();
    const done = await call('POST', '/agent/v1/released', `Device ${device.deviceId}.${device.apiToken}`, {});
    expect(done.status).toBe(200);
  });

  it('records everything in the audit log and exports CSV', async () => {
    const a = await call('GET', '/api/audit', ownerToken);
    const actions = a.body.items.map((i: any) => i.action);
    expect(actions).toEqual(expect.arrayContaining(['device.locked', 'device.unlocked', 'payment.record', 'device.release', 'device.enrolled']));
    const csv = await call('GET', '/api/reports/devices.csv', ownerToken);
    expect(String(csv.body)).toContain('Dinesh');
  });

  it('refuses a sale when the shop has no keys', async () => {
    await call('POST', `/api/admin/merchants/${merchantId}/keys`, adminToken, { platform: 'android', count: -1, reason: 'test' });
    const r = await call('POST', '/api/sales', staffToken, {
      platform: 'android', customer: { name: 'Vikesh', mobile: '7023473415' },
      loan: { totalAmount: 15000, downPayment: 3000, emiAmount: 2000, emiCount: 6, firstEmiDate: todayIST() },
    });
    expect(r.status).toBe(400);
    expect(r.body.message).toContain('No Android keys');
  });
});
