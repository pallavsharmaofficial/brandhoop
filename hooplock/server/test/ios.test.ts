import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import http from 'node:http';
import plist from 'plist';

// A fake NanoMDM that records enqueued commands.
const received: { path: string; auth: string; cmd: any }[] = [];
const fake = http.createServer((req, res) => {
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', () => {
    received.push({ path: req.url!, auth: String(req.headers.authorization), cmd: plist.parse(body) });
    res.writeHead(200).end('{}');
  });
});
await new Promise<void>((r) => fake.listen(0, r));
const port = (fake.address() as any).port;

process.env.DATABASE_URL = process.env.TEST_DATABASE_URL ?? 'postgres://hooplock:hooplock@localhost:5432/hooplock_test';
process.env.NANOMDM_URL = `http://127.0.0.1:${port}`;
process.env.NANOMDM_API_KEY = 'nano-key';
process.env.MDM_WEBHOOK_SECRET = 'hook-secret';

const { buildApp } = await import('../src/app.js');
const { pool, q } = await import('../src/db.js');
const { migrate } = await import('../src/migrate.js');
const { hashPassword } = await import('../src/security.js');
const { todayIST, addMonths } = await import('../src/services/loans.js');

let app: Awaited<ReturnType<typeof buildApp>>;
let owner = '';
let deviceId = '';
const UDID = '00008110-001A2B3C4D5E6F70';

const b64 = (o: object) => Buffer.from(plist.build(o as any)).toString('base64');
async function call(method: string, url: string, body?: unknown, token = owner) {
  const r = await app.inject({ method: method as any, url, headers: token ? { authorization: `Bearer ${token}` } : {}, payload: body as any });
  return { status: r.statusCode, body: r.json() };
}
const hook = (evt: object) => app.inject({ method: 'POST', url: '/mdm/webhook/hook-secret', payload: evt }).then((r) => ({ status: r.statusCode, body: r.json() }));

beforeAll(async () => {
  await pool.query('drop schema public cascade; create schema public;');
  await migrate();
  app = await buildApp({ logger: false });
  const m = await q<{ id: string }>("insert into merchants(name, phone, ios_keys) values ('Brand Hoop','9000000001',1) returning id");
  await q("insert into users(merchant_id, role, name, phone, password_hash) values ($1,'owner','Owner','9000000001',$2)", [m[0].id, await hashPassword('owner-pass-1')]);
  owner = (await call('POST', '/api/auth/login', { phone: '9000000001', password: 'owner-pass-1' }, '')).body.token;
});
afterAll(async () => { await app.close(); await pool.end(); fake.close(); });

describe('iPhone through NanoMDM', () => {
  it('records an iPhone sale by serial', async () => {
    const r = await call('POST', '/api/sales', {
      platform: 'ios', customer: { name: 'Rahul', mobile: '9829000002' }, device: { model: 'iPhone 16', serial: 'f2lxk0abcd12' },
      loan: { totalAmount: 79900, downPayment: 20000, emiAmount: 10000, emiCount: 6, firstEmiDate: addMonths(todayIST(), -1) },
    });
    expect(r.status).toBe(200);
    deviceId = r.body.deviceId;
    const lock = await call('POST', `/api/devices/${deviceId}/state`, { state: 'locked', reason: 'overdue' });
    expect(lock.status).toBe(409); // not enrolled yet
  });

  it('rejects a webhook with the wrong secret', async () => {
    const r = await app.inject({ method: 'POST', url: '/mdm/webhook/nope', payload: {} });
    expect(r.statusCode).toBe(401);
  });

  it('links on Authenticate and activates on the first TokenUpdate', async () => {
    const a = await hook({ topic: 'mdm.Authenticate', checkin_event: { udid: UDID, raw_payload: b64({ MessageType: 'Authenticate', SerialNumber: 'F2LXK0ABCD12', UDID, ProductName: 'iPhone17,3', OSVersion: '19.1' }) } });
    expect(a.body.linked).toBe(deviceId);
    const t = await hook({ topic: 'mdm.TokenUpdate', checkin_event: { udid: UDID, raw_payload: b64({ MessageType: 'TokenUpdate' }) } });
    expect(t.body.activated).toBe(deviceId);
    const d = (await call('GET', `/api/devices/${deviceId}`)).body;
    expect(d.status).toBe('active');
    expect(received[0].path).toBe(`/v1/enqueue/${UDID}`);
    expect(received[0].auth).toBe('Basic ' + Buffer.from('nanomdm:nano-key').toString('base64'));
    expect(received[0].cmd.Command.RequestType).toBe('InstallProfile');
    const profile = plist.parse(Buffer.from(received[0].cmd.Command.Payload).toString()) as any;
    expect(profile.PayloadContent[0].allowEraseContentAndSettings).toBe(false);
    const dash = (await call('GET', '/api/dashboard')).body;
    expect(dash.keys.ios).toBe(0);
  });

  it('locks with Lost Mode, refuses warning, locates, and stores the location', async () => {
    expect((await call('POST', `/api/devices/${deviceId}/state`, { state: 'warning' })).status).toBe(400);
    expect((await call('POST', `/api/devices/${deviceId}/locate`, { reason: 'test locate' })).status).toBe(400);
    const r = await call('POST', `/api/devices/${deviceId}/state`, { state: 'locked', reason: 'overdue', message: 'Pay EMI' });
    expect(r.status).toBe(200);
    const lost = received.at(-1)!.cmd;
    expect(lost.Command).toMatchObject({ RequestType: 'EnableLostMode', Message: 'Pay EMI', PhoneNumber: '9000000001' });
    await hook({ topic: 'mdm.Connect', acknowledge_event: { udid: UDID, status: 'Acknowledged', command_uuid: lost.CommandUUID, raw_payload: b64({ Status: 'Acknowledged' }) } });
    expect((await call('GET', `/api/devices/${deviceId}`)).body.reportedState).toBe('locked');

    expect((await call('POST', `/api/devices/${deviceId}/locate`, { reason: 'customer not reachable' })).status).toBe(200);
    const loc = received.at(-1)!.cmd;
    expect(loc.Command.RequestType).toBe('DeviceLocation');
    await hook({ topic: 'mdm.Connect', acknowledge_event: { udid: UDID, status: 'Acknowledged', command_uuid: loc.CommandUUID, raw_payload: b64({ Latitude: 27.73, Longitude: 75.78, HorizontalAccuracy: 12 }) } });
    const locs = (await call('GET', `/api/devices/${deviceId}/locations`)).body.items;
    expect(locs[0]).toMatchObject({ lat: 27.73, lng: 75.78, reason: 'lost_mode' });
  });

  it('unlocks on payment and releases with RemoveProfile', async () => {
    const pay = await call('POST', `/api/devices/${deviceId}/payments`, { amount: 10000, method: 'cash' });
    expect(pay.body.unlocked).toBe(true);
    expect(received.at(-1)!.cmd.Command.RequestType).toBe('DisableLostMode');
    const rel = await call('POST', `/api/devices/${deviceId}/release`, { force: true });
    expect(rel.status).toBe(200);
    expect(rel.body.appleBusinessManager).toContain('Apple Business Manager');
    expect(received.at(-1)!.cmd.Command).toMatchObject({ RequestType: 'RemoveProfile', Identifier: 'in.hooplock.base' });
  });

  it('flags removal of management', async () => {
    await hook({ topic: 'mdm.CheckOut', checkin_event: { udid: UDID, raw_payload: b64({ MessageType: 'CheckOut' }) } });
    // released phones stay released
    expect((await call('GET', `/api/devices/${deviceId}`)).body.status).toBe('released');
  });
});
